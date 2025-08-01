import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/presentation/screens/settings_page.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:lumeo/presentation/screens/favorites_page.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _gridAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _gridScaleAnimation;
  late Animation<double> _listScaleAnimation;
  final ScrollController _scrollController = ScrollController();

  // Selection state
  final Set<String> _selectedVideos =
      <String>{}; // Store paths of selected videos

  // Lazy loading variables
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupScrollListener();

    // Videos will be loaded automatically by the BLoC
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need for automatic refresh since we use instant updates
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreVideos();
      }
    });
  }

  void _loadMoreVideos() {
    if (!_isLoadingMore) {
      final currentState = context.read<VideoListBloc>().state;
      if (currentState is VideoListLoaded &&
          !currentState.isLoadingMore &&
          currentState.hasMore) {
        context.read<VideoListBloc>().add(const LoadMoreVideos());
      }
    }
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _gridAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _gridScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.elasticOut,
    ));

    _listScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.elasticOut,
    ));

    // Start animations
    _gridAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _listAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: Text(_selectedVideos.isEmpty
            ? 'Video Library'
            : '${_selectedVideos.length} selected'),
        leading: _selectedVideos.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedVideos.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_selectedVideos.isEmpty) ...[
            // Normal mode actions
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context
                    .read<VideoListBloc>()
                    .add(const LoadVideos(forceRefresh: true));
              },
            ),
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) {
                        final bloc = FavoritesBloc.create();
                        BlocCommunicationService.registerFavoritesBloc(bloc);
                        return bloc;
                      },
                      child: const FavoritesPage(),
                    ),
                  ),
                );
              },
            ),
            BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, themeState) {
                final isGridView =
                    themeState is ThemeLoaded ? themeState.isGridView : true;
                return IconButton(
                  icon: Icon(
                    isGridView ? Icons.view_list : Icons.grid_view,
                  ),
                  onPressed: () {
                    context.read<ThemeBloc>().add(ToggleGridView(!isGridView));
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
            ),
          ] else ...[
            // Selection mode actions
            if (_selectedVideos.length == 1)
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () => _showVideoInfo(context, _selectedVideos.first),
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmationForSelected(context),
            ),
          ],
        ],
      ),
      body: BlocBuilder<VideoListBloc, VideoListState>(
        builder: (context, videoState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isGridView =
                  themeState is ThemeLoaded ? themeState.isGridView : true;

              return Column(
                children: [
                  // Enhanced search bar with modern styling
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search videos...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<VideoListBloc>().add(
                                      const LoadVideos(forceRefresh: true));
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          context
                              .read<VideoListBloc>()
                              .add(const LoadVideos(forceRefresh: true));
                        } else {
                          context
                              .read<VideoListBloc>()
                              .add(SearchVideos(value));
                        }
                      },
                    ),
                  ),
                  // Video list/grid
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        // Trigger a force refresh when user pulls down
                        context
                            .read<VideoListBloc>()
                            .add(const LoadVideos(forceRefresh: true));
                        // Wait a bit to show the refresh indicator
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child:
                          _buildVideoContent(context, videoState, isGridView),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVideoContent(
      BuildContext context, VideoListState videoState, bool isGridView) {
    if (videoState is VideoListLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading videos...'),
          ],
        ),
      );
    } else if (videoState is VideoListError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading videos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              videoState.message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context
                    .read<VideoListBloc>()
                    .add(const LoadVideos(forceRefresh: true));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (videoState is VideoListEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No videos found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add some videos to your device to get started\nor pull down to refresh',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<VideoListBloc>()
                    .add(const LoadVideos(forceRefresh: true));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    } else if (videoState is VideoListLoaded) {
      final videos = videoState.videos;
      return AnimatedBuilder(
        animation:
            isGridView ? _gridAnimationController : _listAnimationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isGridView
                ? _gridScaleAnimation.value
                : _listScaleAnimation.value,
            child: isGridView
                ? _buildVideoGrid(context, videos)
                : _buildVideoListView(context, videos),
          );
        },
      );
    }

    // Default loading state
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildVideoGrid(BuildContext context, List<VideoFile> videos) {
    final state = context.read<VideoListBloc>().state;
    final isLoadingMore = state is VideoListLoaded && state.isLoadingMore;

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio:
                  0.7, // Reduced from 0.8 to give more vertical space
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: videos.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= videos.length) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final video = videos[index];
              return _buildVideoCard(context, video);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoListView(BuildContext context, List<VideoFile> videos) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildListCard(context, video),
              );
            },
          ),
        ),
        // Loading indicator
        if (_isLoadingMore)
          Container(
            padding: const EdgeInsets.all(16),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildListCard(BuildContext context, VideoFile video) {
    final bool isSelected = _selectedVideos.contains(video.path);

    return GestureDetector(
      onTap: () {
        if (_selectedVideos.isNotEmpty) {
          setState(() {
            if (isSelected) {
              _selectedVideos.remove(video.path);
            } else {
              _selectedVideos.add(video.path);
            }
          });
        } else {
          // Normal video playback
          context.read<LastPlayedBloc>().add(SetLastPlayedVideo(video));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(
                video: video,
                resumeFromLastPosition: video.lastPlayedPosition != null,
              ),
            ),
          );
        }
      },
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedVideos.remove(video.path);
          } else {
            _selectedVideos.add(video.path);
          }
        });
      },
      onDoubleTap: () {
        if (_selectedVideos.isEmpty) {
          // Toggle favorite on double tap
          context.read<VideoListBloc>().add(ToggleFavorite(video.path));

          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                video.isFavorite
                    ? 'Removed from favorites'
                    : 'Added to favorites',
              ),
              backgroundColor: video.isFavorite ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail with status indicator
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: video.thumbnailBytes != null
                          ? Image.memory(
                              video.thumbnailBytes!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : video.thumbnailPath != null
                              ? Image.file(
                                  File(video.thumbnailPath!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.3),
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.3),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.play_circle_outline,
                                    size: 30,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    top: 4,
                    left: 4,
                    child: _buildStatusIndicator(context, video, true),
                  ),
                  // Favorite indicator
                  if (video.isFavorite)
                    Positioned(
                      bottom: 8,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                  // Resume indicator
                  if (video.lastPlayedPosition != null &&
                      video.duration != null)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              video.lastPlayedPosition!.inMilliseconds /
                                  video.duration!.inMilliseconds,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Video info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (video.duration != null)
                      Text(
                        _formatDuration(video.duration!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    const SizedBox(height: 4),
                    if (video.fileSize != null)
                      Text(
                        _formatFileSize(video.fileSize!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (video.dateAdded != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(video.dateAdded!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Resume text
                    if (video.lastPlayedPosition != null &&
                        video.status != VideoStatus.lastWatched)
                      Text(
                        'Resume from ${_formatDuration(video.lastPlayedPosition!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Play icon
              Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoFile video) {
    final bool isSelected = _selectedVideos.contains(video.path);

    return GestureDetector(
      onTap: () {
        if (_selectedVideos.isNotEmpty) {
          setState(() {
            if (isSelected) {
              _selectedVideos.remove(video.path);
            } else {
              _selectedVideos.add(video.path);
            }
          });
        } else {
          // Normal video playback
          context.read<LastPlayedBloc>().add(SetLastPlayedVideo(video));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(
                video: video,
                resumeFromLastPosition: video.lastPlayedPosition != null,
              ),
            ),
          );
        }
      },
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedVideos.remove(video.path);
          } else {
            _selectedVideos.add(video.path);
          }
        });
      },
      onDoubleTap: () {
        if (_selectedVideos.isEmpty) {
          // Toggle favorite on double tap
          context.read<VideoListBloc>().add(ToggleFavorite(video.path));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                video.isFavorite
                    ? 'Removed from favorites'
                    : 'Added to favorites',
              ),
              backgroundColor: video.isFavorite ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with status indicator
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: video.thumbnailBytes != null
                        ? Image.memory(
                            video.thumbnailBytes!,
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : video.thumbnailPath != null
                            ? Image.file(
                                File(video.thumbnailPath!),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: double.infinity,
                                height: 120,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.3),
                                      Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.3),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_circle_outline,
                                  size: 60,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                  ),
                ),
                // Status indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildStatusIndicator(context, video, true),
                ),
                // Favorite indicator
                if (video.isFavorite)
                  Positioned(
                    bottom: 8,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                // Duration indicator
                if (video.duration != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDuration(video.duration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Resume indicator
                if (video.lastPlayedPosition != null && video.duration != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: video.lastPlayedPosition!.inMilliseconds /
                            video.duration!.inMilliseconds,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Video info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (video.fileSize != null)
                      Text(
                        _formatFileSize(video.fileSize!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (video.dateAdded != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(video.dateAdded!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Resume text
                    if (video.lastPlayedPosition != null &&
                        video.status != VideoStatus.lastWatched)
                      Text(
                        'Resume from ${_formatDuration(video.lastPlayedPosition!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
      BuildContext context, VideoFile video, bool isLastPlayed) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    // Check the stored status first
    if (video.status == VideoStatus.lastWatched) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
      text = 'Last';
      icon = Icons.play_arrow;
    } else if (video.status == VideoStatus.watched) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      text = 'Watched';
      icon = Icons.check;
    } else if (video.status == VideoStatus.watching) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
      text = 'Watching';
      icon = Icons.pause;
    } else {
      // Video has never been played or is new
      backgroundColor = Colors.blue;
      textColor = Colors.white;
      text = 'New';
      icon = Icons.fiber_new;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _showVideoInfo(BuildContext context, String videoPath) {
    final videoState = context.read<VideoListBloc>().state;
    if (videoState is VideoListLoaded) {
      final video = videoState.videos.firstWhere((v) => v.path == videoPath);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Video Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${video.name}'),
              if (video.duration != null)
                Text('Duration: ${_formatDuration(video.duration!)}'),
              if (video.fileSize != null)
                Text('Size: ${_formatFileSize(video.fileSize!)}'),
              if (video.dateAdded != null)
                Text(
                    'Added: ${DateFormat('MMM dd, yyyy').format(video.dateAdded!)}'),
              if (video.lastPlayedPosition != null)
                Text(
                    'Last played at: ${_formatDuration(video.lastPlayedPosition!)}'),
              Text('Favorite: ${video.isFavorite ? 'Yes' : 'No'}'),
              Text('Status: ${video.status.toString().split('.').last}'),
              Text('Path: ${video.path}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showDeleteConfirmationForSelected(BuildContext context) {
    debugPrint(
        'VideoListPage: Showing delete confirmation for selected videos');
    final bloc = context.read<VideoListBloc>();
    final messenger = ScaffoldMessenger.of(context);

    if (_selectedVideos.isEmpty) return;

    final videoState = bloc.state;
    if (videoState is! VideoListLoaded) return;

    final selectedVideoNames = videoState.videos
        .where((v) => _selectedVideos.contains(v.path))
        .map((v) => v.name)
        .toList();

    final message = _selectedVideos.length == 1
        ? 'Are you sure you want to delete "${selectedVideoNames.first}"?'
        : 'Are you sure you want to delete ${_selectedVideos.length} videos?';

    DeleteConfirmationDialog.show(
      context: context,
      videoName: selectedVideoNames.join(', '),
      message: message,
    ).then((result) {
      debugPrint('VideoListPage: Delete confirmation result: $result');
      if (result == true && mounted) {
        debugPrint('VideoListPage: User confirmed deletion');

        final numVideos = _selectedVideos.length;

        // Delete all selected videos at once
        bloc.add(DeleteMultipleVideos(List<String>.from(_selectedVideos)));

        // Clear selection
        setState(() {
          _selectedVideos.clear();
        });

        // Show feedback
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              numVideos == 1 ? '1 video deleted' : '$numVideos videos deleted',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }
}
