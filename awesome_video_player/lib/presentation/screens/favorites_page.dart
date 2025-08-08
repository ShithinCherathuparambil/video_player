import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
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

  void _handleRemoveFromFavorites(VideoFile video) {
    if (!_isSelectionMode) {
      _showFeedback('Removing from favorites...');
      context.read<FavoritesBloc>().add(InstantRemoveFromFavorites(video.path));
      // Update the video list state
      context.read<VideoListBloc>().add(RefreshFromFavorites());
    }
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            _isSelectionMode
                ? '${_selectedVideos.length} selected'
                : 'Favorites',
            style: const TextStyle(color: Colors.white),
          ),
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _cancelSelection,
                )
              : null,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: _deleteSelected,
                  ),
                ]
              : [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {
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
              return const Center(child: CircularProgressIndicator());
            } else if (state is FavoritesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              );
            } else if (state is FavoritesEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.favorite_border, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            } else if (state is FavoritesLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FavoritesBloc>().add(const RefreshFavorites());
                },
                child: _buildGridView(state.favorites),
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
          _toggleSelection(video.path);
        }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with status indicators
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: video.thumbnailBytes != null
                          ? Image.memory(
                              video.thumbnailBytes!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : video.thumbnailPath != null
                              ? Image.file(
                                  File(video.thumbnailPath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
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
                                    size: 48,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                  // Resume indicator
                  if (video.lastPlayedPosition != null &&
                      video.duration != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor:
                              video.lastPlayedPosition!.inMilliseconds /
                                  video.duration!.inMilliseconds,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Selection indicator
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Video info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
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
                          _formatDate(video.dateAdded!),
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
      default:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.circle;
        tooltipText = 'Unknown';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
