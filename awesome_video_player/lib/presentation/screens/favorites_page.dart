import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_event.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_state.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/presentation/widgets/delete_confirmation_dialog.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/presentation/widgets/lazy_thumbnail.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:lumeo/core/utils/video_utils.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Set<String> _selectedVideos = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Refresh favorites when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesBloc>().add(const RefreshFavorites());
    });
  }

  void _toggleSelection(String videoPath) {
    setState(() {
      if (_selectedVideos.contains(videoPath)) {
        _selectedVideos.remove(videoPath);
        if (_selectedVideos.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedVideos.add(videoPath);
        _isSelectionMode = true;
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedVideos.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedVideos.isEmpty) return;

    final confirmed = await DeleteConfirmationDialog.show(
      context: context,
      videoCount: _selectedVideos.length,
    );

    if (confirmed == true && mounted) {
      context
          .read<FavoritesBloc>()
          .add(DeleteMultipleFavorites(_selectedVideos.toList()));
      _cancelSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).colorScheme.secondary.withOpacity(0.05),
              ],
            ),
          ),
        ),
        title: Text(
          _isSelectionMode
              ? '${_selectedVideos.length} selected'
              : 'Favorites',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  _cancelSelection();
                },
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: () {
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.mediumImpact);
                    _deleteSelected();
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () {
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                    context
                        .read<FavoritesBloc>()
                        .add(const RefreshFavorites());
                  },
                ),
              ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return Center(
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          } else if (state is FavoritesError) {
            return Center(
              child: GlassContainer(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          } else if (state is FavoritesEmpty) {
            return Center(
              child: GlassContainer(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80.w,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Double-tap videos to add them',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is FavoritesLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<FavoritesBloc>().add(const RefreshFavorites());
              },
              color: Theme.of(context).colorScheme.primary,
              child: _buildGridView(state.favorites),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildGridView(List<VideoFile> videos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7, // Reduced from 0.8 to give more vertical space
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildVideoCard(context, video);
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoFile video) {
    final bool isSelected = _selectedVideos.contains(video.path);

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
          _toggleSelection(video.path);
        } else {
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
        if (!_isSelectionMode) {
          MicroInteractions.hapticFeedback(type: HapticFeedbackType.mediumImpact);
          _toggleSelection(video.path);
        }
      },
      onDoubleTap: () {
        if (_selectedVideos.isEmpty) {
          MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: GlassContainer(
        depth: isSelected ? 2 : 1,
        borderRadius: BorderRadius.circular(20),
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with status indicators
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: LazyThumbnail(
                      videoPath: video.path,
                      thumbnailPath: video.thumbnailPath,
                      thumbnailBytes: video.thumbnailBytes,
                      width: null,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.4),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.4),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 48,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildStatusIndicator(context, video),
                  ),
                  // Favorite indicator (always visible in favorites)
                  BlocBuilder<VideoListBloc, VideoListState>(
                    key: ValueKey('favorite_fav_${video.path}'),
                    builder: (context, state) {
                      if (state is VideoListLoaded) {
                        final currentVideo = state.videos.firstWhere(
                          (v) => v.path == video.path,
                          orElse: () => video,
                        );

                        // Only show if still in favorites
                        if (currentVideo.isFavorite) {
                          return Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
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
                                size: 16,
                              ),
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Resume progress bar
                  if (video.lastPlayedPosition != null &&
                      video.duration != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              video.lastPlayedPosition!.inMilliseconds /
                                  video.duration!.inMilliseconds,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Selection indicator
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Video info
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (video.duration != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    VideoUtils.formatDuration(video.duration!),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            if (video.fileSize != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storage,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatFileSize(video.fileSize!),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Resume indicator
                    if (video.lastPlayedPosition != null &&
                        video.duration != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_arrow,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Resume from ${VideoUtils.formatDuration(video.lastPlayedPosition!)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildStatusIndicator(BuildContext context, VideoFile video) {
    Color indicatorColor;
    IconData indicatorIcon;
    String tooltipText;

    switch (video.status) {
      case VideoStatus.new_:
        indicatorColor = Colors.green;
        indicatorIcon = Icons.fiber_new;
        tooltipText = 'New';
        break;
      case VideoStatus.watching:
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.play_circle_filled;
        tooltipText = 'In Progress';
        break;
      case VideoStatus.lastWatched:
        indicatorColor = Colors.blue;
        indicatorIcon = Icons.check_circle;
        tooltipText = 'Recently Watched';
        break;
      case VideoStatus.watched:
        indicatorColor = Colors.purple;
        indicatorIcon = Icons.done_all;
        tooltipText = 'Watched';
        break;
    }

    return Tooltip(
      message: tooltipText,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: indicatorColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: indicatorColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          indicatorIcon,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }


  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

}
