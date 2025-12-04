import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/usecases/get_videos.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart'; // For Impl and PermissionDeniedException
import 'package:lumeo/data/repositories/video_repository_impl.dart';
import 'package:lumeo/core/security/path_validator.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';
import './video_list_event.dart';
import './video_list_state.dart';

class VideoListBloc extends Bloc<VideoListEvent, VideoListState> {
  final GetVideos getVideos;
  List<VideoFile> _allVideos = [];
  List<VideoFile>? _searchResults;
  bool _isInitialized = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _pageSize = 20;

  VideoListBloc._({required this.getVideos}) : super(const VideoListInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<LoadMoreVideos>(_onLoadMoreVideos);
    on<SearchVideos>(_onSearchVideos);
    on<UpdateVideoStatus>(_onUpdateVideoStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DeleteVideo>(_onDeleteVideo);
    on<DeleteMultipleVideos>(_onDeleteMultipleVideos);
    on<RefreshFromFavorites>(_onRefreshFromFavorites);
    on<InstantRemoveFromList>(_onInstantRemoveFromList);
    on<SortVideos>(_onSortVideos);

    // Automatically load videos when BLoC is created
    add(const LoadVideos());
  }

  String _getErrorMessage(Object e) {
    final error = e.toString().toLowerCase();
    if (error.contains('permission')) {
      return 'Permission denied. Please grant photo library access in settings.';
    } else if (error.contains('cache')) {
      return 'Failed to access video files. Please check your device storage.';
    }
    return 'Error: ${e.toString()}';
  }

  factory VideoListBloc.create() {
    final videoLocalDataSource = VideoLocalDataSourceImpl();
    final videoRepository =
        VideoRepositoryImpl(localDataSource: videoLocalDataSource);
    final getVideosUseCase = GetVideos(videoRepository);
    return VideoListBloc._(getVideos: getVideosUseCase);
  }

  Future<void> _onLoadVideos(
      LoadVideos event, Emitter<VideoListState> emit) async {
    // If forceRefresh, clear repository cache and reset pagination
    if (event.forceRefresh) {
      final repo = getVideos.repository;
      if (repo is VideoRepositoryImpl) {
        await repo.refreshCache();
      }
      _isInitialized = false;
      _currentPage = 0;
      _allVideos.clear();
    }

    // Don't reload if already initialized and not forced
    if (_isInitialized && !event.forceRefresh) {
      if (_allVideos.isEmpty) {
        emit(const VideoListEmpty());
      } else {
        emit(VideoListLoaded(_allVideos));
      }
      return;
    }

    emit(const VideoListLoading());
    try {
      final videos = await getVideos(page: 0, pageSize: _pageSize);
      _allVideos = videos;
      _isInitialized = true;
      _currentPage = 0;

      if (videos.isEmpty) {
        emit(const VideoListEmpty());
      } else {
        emit(VideoListLoaded(videos, hasMore: videos.length >= _pageSize));
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
      String errorMessage = _getErrorMessage(e);
      emit(VideoListError(errorMessage));
    }
  }

  Future<void> _onLoadMoreVideos(
      LoadMoreVideos event, Emitter<VideoListState> emit) async {
    if (_isLoadingMore || state is! VideoListLoaded) return;

    final currentState = state as VideoListLoaded;
    if (!currentState.hasMore) return;

    try {
      _isLoadingMore = true;
      emit(currentState.copyWith(isLoadingMore: true));

      final nextPage = _currentPage + 1;
      final moreVideos = await getVideos(page: nextPage, pageSize: _pageSize);

      if (moreVideos.isEmpty) {
        emit(currentState.copyWith(
          hasMore: false,
          isLoadingMore: false,
        ));
        return;
      }

      _currentPage = nextPage;
      _allVideos.addAll(moreVideos);

      emit(VideoListLoaded(
        _allVideos,
        hasMore: moreVideos.length >= _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      if (state is VideoListLoaded) {
        emit((state as VideoListLoaded).copyWith(isLoadingMore: false));
      }
      String errorMessage;
      if (e.toString().contains('PermissionDeniedException')) {
        errorMessage =
            'Permission denied. Please grant photo library access in settings.';
      } else if (e.toString().contains('CacheException')) {
        errorMessage =
            'Failed to access video files. Please check your device storage.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      emit(VideoListError(errorMessage));
    } finally {
      _isLoadingMore = false;
    }
  }

  void _onSearchVideos(SearchVideos event, Emitter<VideoListState> emit) {
    // Sanitize search query for security
    final sanitizedQuery = PathValidator.sanitizeSearchQuery(event.query);

    if (sanitizedQuery.isEmpty) {
      emit(VideoListLoaded(_allVideos));
    } else {
      final filteredVideos = _allVideos
          .where((video) =>
              video.name.toLowerCase().contains(sanitizedQuery.toLowerCase()))
          .toList();
      emit(VideoListLoaded(filteredVideos));
    }
  }

  void _onUpdateVideoStatus(
      UpdateVideoStatus event, Emitter<VideoListState> emit) {
    // Find and update the video status instantly - try multiple matching strategies
    int videoIndex = _allVideos.indexWhere((v) => v.path == event.videoPath);

    // If exact match fails, try matching by filename
    if (videoIndex == -1) {
      final eventFileName = event.videoPath.split('/').last;
      videoIndex =
          _allVideos.indexWhere((v) => v.path.split('/').last == eventFileName);
    }

    // If still not found, try matching by name
    if (videoIndex == -1) {
      final eventFileName = event.videoPath.split('/').last;
      videoIndex = _allVideos.indexWhere((v) => v.name.contains(eventFileName));
    }

    if (videoIndex != -1) {
      // If setting to "lastWatched", clear "lastWatched" from all other videos
      if (event.newStatus == VideoStatus.lastWatched) {
        for (int i = 0; i < _allVideos.length; i++) {
          if (i != videoIndex &&
              _allVideos[i].status == VideoStatus.lastWatched) {
            _allVideos[i] = _allVideos[i].copyWith(status: VideoStatus.watched);
          }
        }
      }

      // If setting to "watching", clear "watching" from all other videos
      if (event.newStatus == VideoStatus.watching) {
        for (int i = 0; i < _allVideos.length; i++) {
          if (i != videoIndex && _allVideos[i].status == VideoStatus.watching) {
            _allVideos[i] = _allVideos[i].copyWith(status: VideoStatus.watched);
          }
        }
      }

      final updatedVideo = _allVideos[videoIndex].copyWith(
        status: event.newStatus,
        lastPlayedPosition: event.lastPosition,
        lastPlayedAt: DateTime.now(),
      );

      // Update the video in the list
      _allVideos[videoIndex] = updatedVideo;

      // Create a new list to ensure state change is detected
      final newVideosList = List<VideoFile>.from(_allVideos);

      // Emit the updated state immediately
      final newState = VideoListLoaded(newVideosList);
      emit(newState);

      // Save to repository in background (don't wait for it)
      _saveVideoStatusInBackground(updatedVideo);
    }
    // If video not found, silently ignore (could be from different source)
  }

  Future<void> _saveVideoStatusInBackground(VideoFile video) async {
    try {
      final repo = getVideos.repository;
      if (repo is VideoRepositoryImpl) {
        await repo.saveVideoMetadata(video);
      }
    } catch (e) {
      // Don't emit error state - user doesn't need to know about background save failures
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavorite event, Emitter<VideoListState> emit) async {
    if (state is! VideoListLoaded) return;

    try {
      final currentState = state as VideoListLoaded;
      final currentVideos = currentState.videos;

      // Find video in current visible list
      final videoIndex =
          currentVideos.indexWhere((v) => v.path == event.videoPath);
      if (videoIndex != -1) {
        // Create updated video with toggled favorite status
        final video = currentVideos[videoIndex];
        final updatedVideo = video.copyWith(isFavorite: !video.isFavorite);

        // Update the videos in both lists while maintaining references
        final updatedVideos = List<VideoFile>.from(currentVideos);
        updatedVideos[videoIndex] = updatedVideo;

        // Update in _allVideos list
        final mainIndex =
            _allVideos.indexWhere((v) => v.path == event.videoPath);
        if (mainIndex != -1) {
          _allVideos[mainIndex] = updatedVideo;
        }

        // If we're showing search results, update them too
        if (_searchResults != null) {
          final searchIndex =
              _searchResults!.indexWhere((v) => v.path == event.videoPath);
          if (searchIndex != -1) {
            _searchResults![searchIndex] = updatedVideo;
          }
        }

        // Emit new state while preserving the current view state
        // Create a new list instance to ensure state change is detected
        final newVideosList = List<VideoFile>.from(updatedVideos);
        emit(VideoListLoaded(
          newVideosList,
          hasMore: currentState.hasMore,
          isLoadingMore: currentState.isLoadingMore,
        ));

        // Update repository in background without blocking UI
        try {
          final repo = getVideos.repository;
          if (repo is VideoRepositoryImpl) {
            unawaited(repo.toggleFavorite(event.videoPath));
          }
        } catch (e) {
          debugPrint('Error updating favorite status in repository: $e');
          // Don't emit error state since UI is already updated
        }
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Don't emit error state since UI is already updated
    }
  }

  Future<void> _onDeleteVideo(
      DeleteVideo event, Emitter<VideoListState> emit) async {
    try {
      debugPrint(
          'VideoListBloc: Attempting to delete video: ${event.videoPath}');

      // Find the video to delete
      final videoIndex =
          _allVideos.indexWhere((v) => v.path == event.videoPath);
      if (videoIndex == -1) {
        debugPrint(
            'VideoListBloc: Video not found in list: ${event.videoPath}');
        return;
      }

      debugPrint('VideoListBloc: Found video at index $videoIndex');

      // Delete from repository (this will delete the file and metadata)
      await getVideos.repository.deleteVideo(event.videoPath);
      debugPrint('VideoListBloc: Successfully deleted video from repository');

      // Remove from local list
      _allVideos.removeAt(videoIndex);

      // Emit updated state
      emit(VideoListLoaded(List<VideoFile>.from(_allVideos)));

      // Notify favorites bloc
      BlocCommunicationService.notifyFavoritesOfDeletion(event.videoPath);
    } catch (e) {
      debugPrint('VideoListBloc: Error deleting video: $e');
      final errorMessage = 'Error deleting video: ${e.toString()}';
      emit(VideoListError(errorMessage));
    }
  }

  Future<void> _onDeleteMultipleVideos(
      DeleteMultipleVideos event, Emitter<VideoListState> emit) async {
    try {
      debugPrint(
          'VideoListBloc: Attempting to delete ${event.videoPaths.length} videos');

      // Track which videos were successfully deleted
      final successfullyDeletedPaths = <String>[];

      // Try to delete each video
      for (final path in event.videoPaths) {
        try {
          await getVideos.repository.deleteVideo(path);
          successfullyDeletedPaths.add(path);
          BlocCommunicationService.notifyFavoritesOfDeletion(path);
        } catch (e) {
          debugPrint('VideoListBloc: Error deleting video $path: $e');
          // Continue with other deletions even if one fails
        }
      }

      // Remove successfully deleted videos from local list
      _allVideos.removeWhere((v) => successfullyDeletedPaths.contains(v.path));

      // Update state with remaining videos
      emit(VideoListLoaded(List<VideoFile>.from(_allVideos)));

      debugPrint(
          'VideoListBloc: Successfully deleted ${successfullyDeletedPaths.length} videos');

      // Clear repository cache to ensure other screens get updated data
      final repo = getVideos.repository;
      if (repo is VideoRepositoryImpl) {
        await repo.refreshCache();
      }
    } catch (e) {
      debugPrint('VideoListBloc: Error in batch deletion: $e');
      final errorMessage = _getDeleteErrorMessage(e);
      emit(VideoListError(errorMessage));

      // After showing error, go back to loaded state
      Future.delayed(const Duration(seconds: 3), () {
        emit(VideoListLoaded(List<VideoFile>.from(_allVideos)));
      });
    }
  }

  String _getDeleteErrorMessage(Object e) {
    final error = e.toString().toLowerCase();
    if (error.contains('storage permission denied')) {
      return 'Storage permission required to delete videos. Please grant permission and try again.';
    } else if (error.contains('protected location') ||
        error.contains('currently in use')) {
      return 'Cannot delete this video - it may be protected or currently in use.';
    } else if (error.contains('mediastore deletion failed')) {
      return 'Unable to delete video from device storage. The file may be protected.';
    } else if (error.contains('permission denied')) {
      return 'Permission denied. Cannot delete this video file.';
    } else if (error.contains('not found')) {
      return 'Video file not found.';
    }
    return 'Failed to delete video';
  }

  Future<void> _onRefreshFromFavorites(
      RefreshFromFavorites event, Emitter<VideoListState> emit) async {
    debugPrint('VideoListBloc: Refreshing from favorites deletion');

    // Clear cache and reload videos
    final repo = getVideos.repository;
    if (repo is VideoRepositoryImpl) {
      await repo.refreshCache();
    }

    // Force reload videos
    _isInitialized = false;
    add(const LoadVideos(forceRefresh: true));
  }

  void _onSortVideos(SortVideos event, Emitter<VideoListState> emit) {
    if (state is! VideoListLoaded) return;

    final currentState = state as VideoListLoaded;
    final sortedVideos = List<VideoFile>.from(currentState.videos);

    switch (event.sortOption) {
      case VideoSortOption.nameAscending:
        sortedVideos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case VideoSortOption.nameDescending:
        sortedVideos.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case VideoSortOption.dateAscending:
        sortedVideos.sort((a, b) {
          final aDate = a.dateAdded ?? DateTime(1970);
          final bDate = b.dateAdded ?? DateTime(1970);
          return aDate.compareTo(bDate);
        });
        break;
      case VideoSortOption.dateDescending:
        sortedVideos.sort((a, b) {
          final aDate = a.dateAdded ?? DateTime(1970);
          final bDate = b.dateAdded ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case VideoSortOption.sizeAscending:
        sortedVideos.sort((a, b) {
          final aSize = a.fileSize ?? 0;
          final bSize = b.fileSize ?? 0;
          return aSize.compareTo(bSize);
        });
        break;
      case VideoSortOption.sizeDescending:
        sortedVideos.sort((a, b) {
          final aSize = a.fileSize ?? 0;
          final bSize = b.fileSize ?? 0;
          return bSize.compareTo(aSize);
        });
        break;
      case VideoSortOption.durationAscending:
        sortedVideos.sort((a, b) {
          final aDuration = a.duration?.inMilliseconds ?? 0;
          final bDuration = b.duration?.inMilliseconds ?? 0;
          return aDuration.compareTo(bDuration);
        });
        break;
      case VideoSortOption.durationDescending:
        sortedVideos.sort((a, b) {
          final aDuration = a.duration?.inMilliseconds ?? 0;
          final bDuration = b.duration?.inMilliseconds ?? 0;
          return bDuration.compareTo(aDuration);
        });
        break;
    }

    _allVideos = sortedVideos;
    emit(VideoListLoaded(sortedVideos, hasMore: currentState.hasMore));
  }

  Future<void> _onInstantRemoveFromList(
      InstantRemoveFromList event, Emitter<VideoListState> emit) async {
    debugPrint('VideoListBloc: Instantly removing video: ${event.videoPath}');

    // Find and remove the video from local list
    final videoIndex = _allVideos.indexWhere((v) => v.path == event.videoPath);
    if (videoIndex != -1) {
      _allVideos.removeAt(videoIndex);
      debugPrint(
          'VideoListBloc: Instantly removed video from list, new count: ${_allVideos.length}');

      // Emit updated state immediately
      emit(VideoListLoaded(List<VideoFile>.from(_allVideos)));
      debugPrint(
          'VideoListBloc: Instantly emitted new state with ${_allVideos.length} videos');
    }
  }
}
