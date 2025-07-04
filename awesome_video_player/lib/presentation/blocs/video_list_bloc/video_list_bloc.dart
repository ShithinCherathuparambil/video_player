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
  bool _isInitialized = false;

  VideoListBloc({required this.getVideos}) : super(const VideoListInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<SearchVideos>(_onSearchVideos);
    on<UpdateVideoStatus>(_onUpdateVideoStatus);
    on<ToggleFavorite>(_onToggleFavorite);
    on<DeleteVideo>(_onDeleteVideo);
    on<RefreshFromFavorites>(_onRefreshFromFavorites);
    on<InstantRemoveFromList>(_onInstantRemoveFromList);

    // Automatically load videos when BLoC is created
    add(const LoadVideos());
  }

  Future<void> _onLoadVideos(
      LoadVideos event, Emitter<VideoListState> emit) async {
    // If forceRefresh, clear repository cache
    if (event.forceRefresh) {
      final repo = getVideos.repository;
      if (repo is VideoRepositoryImpl) {
        await repo.refreshCache();
      }
      _isInitialized = false;
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
      final videos = await getVideos();
      _allVideos = videos;
      _isInitialized = true;

      if (videos.isEmpty) {
        emit(const VideoListEmpty());
      } else {
        emit(VideoListLoaded(videos));
      }
    } catch (e) {
      String errorMessage = 'Failed to load videos';

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

  void _onToggleFavorite(
      ToggleFavorite event, Emitter<VideoListState> emit) async {
    try {
      // Find the video in the list
      final videoIndex =
          _allVideos.indexWhere((v) => v.path == event.videoPath);

      if (videoIndex != -1) {
        final video = _allVideos[videoIndex];
        final updatedVideo = video.copyWith(isFavorite: !video.isFavorite);

        // Update the video in the list
        _allVideos[videoIndex] = updatedVideo;

        // Create a new list to ensure state change is detected
        final newVideosList = List<VideoFile>.from(_allVideos);

        // Emit the updated state immediately
        final newState = VideoListLoaded(newVideosList);
        emit(newState);

        // Save to repository in background
        final repo = getVideos.repository;
        if (repo is VideoRepositoryImpl) {
          await repo.toggleFavorite(event.videoPath);
        }
      }
    } catch (e) {
      // Handle error silently
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
      debugPrint(
          'VideoListBloc: Removed video from local list, new count: ${_allVideos.length}');

      // Emit updated state immediately
      final newState = VideoListLoaded(List<VideoFile>.from(_allVideos));
      emit(newState);
      debugPrint(
          'VideoListBloc: Emitted new state with ${_allVideos.length} videos');

      // Clear repository cache to ensure other screens get updated data
      final repo = getVideos.repository;
      if (repo is VideoRepositoryImpl) {
        await repo.refreshCache();
      }

      // Instantly notify favorites bloc to remove this video
      BlocCommunicationService.notifyFavoritesOfDeletion(event.videoPath);
    } catch (e) {
      // Handle error - emit an error state with user-friendly message
      debugPrint('VideoListBloc: Error deleting video: $e');

      String errorMessage = 'Failed to delete video';
      if (e.toString().contains('Storage permission denied')) {
        errorMessage =
            'Storage permission required to delete videos. Please grant permission and try again.';
      } else if (e.toString().contains('protected location') ||
          e.toString().contains('currently in use')) {
        errorMessage =
            'Cannot delete this video - it may be protected or currently in use.';
      } else if (e.toString().contains('MediaStore deletion failed')) {
        errorMessage =
            'Unable to delete video from device storage. The file may be protected.';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage = 'Permission denied. Cannot delete this video file.';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Video file not found.';
      }

      emit(VideoListError(errorMessage));

      // After showing error, go back to loaded state
      Future.delayed(const Duration(seconds: 3), () {
        if (!emit.isDone) {
          emit(VideoListLoaded(List<VideoFile>.from(_allVideos)));
        }
      });
    }
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
      final newState = VideoListLoaded(List<VideoFile>.from(_allVideos));
      emit(newState);
      debugPrint(
          'VideoListBloc: Instantly emitted new state with ${_allVideos.length} videos');
    }
  }

  // Static create method for simplified DI as per subtask guideline
  static VideoListBloc create() {
    // VideoLocalDataSourceImpl doesn't need SharedPreferences, so it's simpler
    final videoLocalDataSource = VideoLocalDataSourceImpl();
    final videoRepository =
        VideoRepositoryImpl(localDataSource: videoLocalDataSource);
    final getVideosUseCase = GetVideos(videoRepository);

    return VideoListBloc(getVideos: getVideosUseCase);
  }
}
