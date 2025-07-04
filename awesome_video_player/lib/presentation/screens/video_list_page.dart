import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/presentation/screens/settings_page.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_state.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart';
import 'package:lumeo/presentation/screens/favorites_page.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';

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
  late AnimationController _cardAnimationController;
  late Animation<double> _gridScaleAnimation;
  late Animation<double> _listScaleAnimation;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  final ScrollController _scrollController = ScrollController();

  // Lazy loading variables
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

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
      setState(() {
        _isLoadingMore = true;
      });

      // Load more videos - for now just reload all videos
      context.read<VideoListBloc>().add(LoadVideos());

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      });
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
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

    _cardScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _gridAnimationController.forward();
    _listAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _gridAnimationController.dispose();
    _listAnimationController.dispose();
    _cardAnimationController.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Library'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context
                  .read<VideoListBloc>()
                  .add(const LoadVideos(forceRefresh: true));
            },
          ),
          // Favorites button
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
          // View toggle button
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
          // Settings button
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
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return _buildVideoCard(context, video);
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
    return GestureDetector(
      onTap: () async {
        // Save as last played video
        context.read<LastPlayedBloc>().add(SetLastPlayedVideo(video));

        // Navigate to video player with resume position
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              video: video,
              resumeFromLastPosition: video.lastPlayedPosition != null,
            ),
          ),
        );

        // No need to refresh since we use instant updates
      },
      onDoubleTap: () {
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
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
              // Action buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Delete button
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(context, video),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
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
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Play icon
                  Icon(
                    Icons.play_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoFile video) {
    return GestureDetector(
      onTap: () async {
        // Save as last played video
        context.read<LastPlayedBloc>().add(SetLastPlayedVideo(video));

        // Navigate to video player with resume position
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              video: video,
              resumeFromLastPosition: video.lastPlayedPosition != null,
            ),
          ),
        );

        // No need to refresh since we use instant updates
      },
      onDoubleTap: () {
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
      },
      child: Container(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with status indicator
                Stack(
                  children: [
                    Container(
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                    // Delete button
                    Positioned(
                      top: 8,
                      right: video.duration != null
                          ? 80
                          : 8, // Adjust position based on duration indicator
                      child: GestureDetector(
                        onTap: () => _showDeleteConfirmation(context, video),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
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
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
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
                    if (video.lastPlayedPosition != null &&
                        video.duration != null)
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
                // Video info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
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

  void _showDeleteConfirmation(BuildContext context, VideoFile video) {
    debugPrint('VideoListPage: Showing delete confirmation for: ${video.name}');
    final bloc = context.read<VideoListBloc>();
    final messenger = ScaffoldMessenger.of(context);

    DeleteConfirmationDialog.show(
      context: context,
      videoName: video.name,
    ).then((result) {
      debugPrint('VideoListPage: Delete confirmation result: $result');
      if (result == true && mounted) {
        debugPrint(
            'VideoListPage: User confirmed deletion, dispatching DeleteVideo event');

        // Listen for the result of the deletion
        late StreamSubscription subscription;
        subscription = bloc.stream.listen((state) {
          if (mounted) {
            if (state is VideoListLoaded) {
              // Check if the video was successfully removed from the list
              final videoStillExists =
                  state.videos.any((v) => v.path == video.path);
              if (!videoStillExists) {
                // Video was successfully deleted
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${video.name} deleted successfully'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
                subscription.cancel();
              }
            } else if (state is VideoListError) {
              // Show error message
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                ),
              );
              subscription.cancel();
            }
          }
        });

        // Cancel subscription after a reasonable time to prevent memory leaks
        Future.delayed(const Duration(seconds: 10), () {
          subscription.cancel();
        });

        // User confirmed deletion
        bloc.add(DeleteVideo(video.path));
      } else {
        debugPrint(
            'VideoListPage: User cancelled deletion or widget not mounted');
      }
    });
  }
}
