import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_event.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/presentation/screens/settings_page.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_event.dart';
import './favorites_page.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';

import 'package:lumeo/presentation/widgets/recently_watched_section.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/presentation/screens/playback_history_page.dart';
import 'package:lumeo/presentation/widgets/lazy_thumbnail.dart';

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
      body: BlocBuilder<VideoListBloc, VideoListState>(
        builder: (context, videoState) {
          return BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              final isGridView =
                  themeState is ThemeLoaded ? themeState.isGridView : true;

              return RefreshIndicator(
                onRefresh: () async {
                  context
                      .read<VideoListBloc>()
                      .add(const LoadVideos(forceRefresh: true));
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    _buildSliverAppBar(context, isGridView),
                    SliverToBoxAdapter(
                      child: _buildSearchBar(context),
                    ),
                    _buildVideoContentSliver(context, videoState, isGridView),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isGridView) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      snap: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        _selectedVideos.isEmpty
            ? 'Video Library'
            : '${_selectedVideos.length} selected',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context
                  .read<VideoListBloc>()
                  .add(const LoadVideos(forceRefresh: true));
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
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
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Playback History',
            onPressed: () {
              final currentState = context.read<VideoListBloc>().state;
              if (currentState is VideoListLoaded) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaybackHistoryPage(
                      allVideos: currentState.videos,
                    ),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: Icon(
              isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () {
              context.read<ThemeBloc>().add(ToggleGridView(!isGridView));
            },
          ),
          _buildMoreOptionsButton(context),
        ] else ...[
          if (_selectedVideos.length == 1)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showVideoInfo(context, _selectedVideos.first),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showDeleteConfirmationForSelected(context),
          ),
        ],
      ],
    );
  }

  Widget _buildMoreOptionsButton(BuildContext context) {
    return PopupMenuButton<VideoSortOption>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More options',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (option) {
        context.read<VideoListBloc>().add(SortVideos(option));
        MicroInteractions.hapticFeedback(
          type: HapticFeedbackType.selectionClick,
        );
      },
      itemBuilder: (context) => [
        const PopupMenuItem<VideoSortOption>(
          enabled: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Sort by',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.nameAscending,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 20),
              SizedBox(width: 8),
              Text('Name (A-Z)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.nameDescending,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 20),
              SizedBox(width: 8),
              Text('Name (Z-A)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.dateDescending,
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20),
              SizedBox(width: 8),
              Text('Date (Newest)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.dateAscending,
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 20),
              SizedBox(width: 8),
              Text('Date (Oldest)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.sizeDescending,
          child: Row(
            children: [
              Icon(Icons.storage, size: 20),
              SizedBox(width: 8),
              Text('Size (Largest)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.sizeAscending,
          child: Row(
            children: [
              Icon(Icons.storage, size: 20),
              SizedBox(width: 8),
              Text('Size (Smallest)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.durationDescending,
          child: Row(
            children: [
              Icon(Icons.timer, size: 20),
              SizedBox(width: 8),
              Text('Duration (Longest)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: VideoSortOption.durationAscending,
          child: Row(
            children: [
              Icon(Icons.timer, size: 20),
              SizedBox(width: 8),
              Text('Duration (Shortest)'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: true,
          onTap: () {
            Future.delayed(const Duration(milliseconds: 10), () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            });
          },
          child: const Row(
            children: [
              Icon(Icons.settings, size: 20),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search your videos...',
          hintStyle: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.7)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    context
                        .read<VideoListBloc>()
                        .add(const LoadVideos(forceRefresh: true));
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            context
                .read<VideoListBloc>()
                .add(const LoadVideos(forceRefresh: true));
          } else {
            context.read<VideoListBloc>().add(SearchVideos(value));
          }
        },
      ),
    );
  }

  Widget _buildVideoContentSliver(
      BuildContext context, VideoListState videoState, bool isGridView) {
    if (videoState is VideoListLoading) {
      return _buildShimmerLoadingSliver(isGridView);
    } else if (videoState is VideoListError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
        ),
      );
    } else if (videoState is VideoListEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
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
        ),
      );
    } else if (videoState is VideoListLoaded) {
      final videos = videoState.videos;
      // Using a list of slivers via SliverMainAxisGroup if available, or just returning a single Sliver wrapper.
      // Since we want to return a single widget but have multiple sections, and we are inside a CustomScrollView's slivers list,
      // we can't easily return multiple pointers.
      // However, we are replacing the call inside the CustomScrollView.
      // My implementation above was: `_buildVideoContentSliver(...)` inside `slivers: [...]`.
      // So this method MUST return a single Widget that is a Sliver.
      // `SliverMainAxisGroup` is the best choice (Flutter 3.13+).
      // Assuming modern Flutter.
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: RecentlyWatchedSection(allVideos: videos),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          isGridView
              ? _buildVideoGridSliver(context, videos)
              : _buildVideoListSliver(context, videos),
          // Add some bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      );
    }

    return _buildShimmerLoadingSliver(isGridView);
  }

  Widget _buildShimmerLoadingSliver(bool isGridView) {
    return isGridView
        ? SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildShimmerCard(),
                childCount: 6,
              ),
            ),
          )
        : SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildShimmerListCard(),
                ),
                childCount: 6,
              ),
            ),
          );
  }

  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerListCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGridSliver(BuildContext context, List<VideoFile> videos) {
    final state = context.read<VideoListBloc>().state;
    final isLoadingMore = state is VideoListLoaded && state.isLoadingMore;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // Adjusted for better look
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
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
          childCount: videos.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildVideoListSliver(BuildContext context, List<VideoFile> videos) {
    final state = context.read<VideoListBloc>().state;
    final isLoadingMore = state is VideoListLoaded && state.isLoadingMore;

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= videos.length) {
              return Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final video = videos[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildListCard(context, video),
            );
          },
          childCount: videos.length + (isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, VideoFile video) {
    final bool isSelected = _selectedVideos.contains(video.path);

    return Dismissible(
      key: Key('list_${video.path}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          context.read<VideoListBloc>().add(ToggleFavorite(video.path));
          final favoritesBloc = BlocCommunicationService.getFavoritesBloc();
          if (favoritesBloc != null && video.isFavorite) {
            favoritesBloc.add(InstantRemoveFromFavorites(video.path));
          }
          MicroInteractions.hapticFeedback(
            type: HapticFeedbackType.mediumImpact,
          );
        } else if (direction == DismissDirection.endToStart) {
          context.read<VideoListBloc>().add(DeleteVideo(video.path));
          MicroInteractions.hapticFeedback(
            type: HapticFeedbackType.heavyImpact,
          );
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context, video) ?? false;
        }
        return true;
      },
      child: GestureDetector(
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
            final wasInFavorites = video.isFavorite;

            // Update video list state
            context.read<VideoListBloc>().add(ToggleFavorite(video.path));

            // Update favorites bloc state
            final favoritesBloc = BlocCommunicationService.getFavoritesBloc();
            if (favoritesBloc != null && wasInFavorites) {
              favoritesBloc.add(InstantRemoveFromFavorites(video.path));
            }

            // Show feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  wasInFavorites
                      ? 'Removed from favorites'
                      : 'Added to favorites',
                ),
                backgroundColor: wasInFavorites ? Colors.orange : Colors.green,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 100, // Fixed height for list items
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2.5)
                : Border.all(color: Colors.transparent, width: 0),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // Thumbnail
              SizedBox(
                width: 120,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LazyThumbnail(
                      videoPath: video.path,
                      thumbnailPath: video.thumbnailPath,
                      thumbnailBytes: video.thumbnailBytes,
                      width: null,
                      height: null,
                      fit: BoxFit.cover,
                    ),
                    if (video.duration != null)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDuration(video.duration!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (video.lastPlayedPosition != null &&
                        video.duration != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: video.lastPlayedPosition!.inMilliseconds /
                              video.duration!.inMilliseconds,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                          minHeight: 3,
                        ),
                      ),
                    if (isSelected)
                      Container(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.2),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        video.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (video.fileSize != null)
                            Text(
                              _formatFileSize(video.fileSize!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                            ),
                          const SizedBox(width: 8),
                          if (video.isFavorite)
                            const Icon(Icons.favorite_rounded,
                                size: 14, color: Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show bottom sheet or menu
                  _showVideoInfo(context, video.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
      BuildContext context, VideoFile video) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<VideoListBloc>().add(DeleteVideo(video.path));
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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
          final wasInFavorites = video.isFavorite;
          context.read<VideoListBloc>().add(ToggleFavorite(video.path));

          final favoritesBloc = BlocCommunicationService.getFavoritesBloc();
          if (favoritesBloc != null && wasInFavorites) {
            favoritesBloc.add(InstantRemoveFromFavorites(video.path));
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                wasInFavorites
                    ? 'Removed from favorites'
                    : 'Added to favorites',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  wasInFavorites ? Colors.orange : const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).colorScheme.surface,
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2.5)
              : Border.all(color: Colors.transparent, width: 0),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail container
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LazyThumbnail(
                    videoPath: video.path,
                    thumbnailPath: video.thumbnailPath,
                    thumbnailBytes: video.thumbnailBytes,
                    width: null,
                    height: null,
                    fit: BoxFit.cover,
                  ),
                  // Gradient Overlay for readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  // Status
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildStatusIndicator(context, video, true),
                  ),
                  // Favorite
                  if (video.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Colors.red,
                          size: 14,
                        ),
                      ),
                    ),
                  // Duration
                  if (video.duration != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatDuration(video.duration!),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Progress Bar
                  if (video.lastPlayedPosition != null &&
                      video.duration != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: video.lastPlayedPosition!.inMilliseconds /
                            video.duration!.inMilliseconds,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary),
                        minHeight: 3,
                      ),
                    ),
                  if (isSelected)
                    Container(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (video.fileSize != null)
                          Text(
                            _formatFileSize(video.fileSize!),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary),
                          ),
                        const Spacer(),
                        if (video.dateAdded != null)
                          Text(
                            DateFormat('MMM d').format(video.dateAdded!),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    fontSize: 10,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                          ),
                      ],
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
    Color color;
    String text;
    IconData icon;

    if (video.status == VideoStatus.lastWatched) {
      color = Theme.of(context).colorScheme.primary;
      text = 'Last Watched';
      icon = Icons.play_arrow_rounded;
    } else if (video.status == VideoStatus.watched) {
      color = Colors.green;
      text = 'Completed';
      icon = Icons.check_circle_rounded;
    } else if (video.status == VideoStatus.watching) {
      color = Colors.orange;
      text = 'Watching';
      icon = Icons.timelapse_rounded;
    } else {
      color = Colors.blue;
      text = 'New';
      icon = Icons.new_releases_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
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
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
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
