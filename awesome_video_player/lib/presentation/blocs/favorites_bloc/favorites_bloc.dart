import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/usecases/get_favorite_videos.dart';
import 'package:lumeo/domain/usecases/toggle_favorite.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart';
import 'package:lumeo/data/repositories/video_repository_impl.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';
import './favorites_event.dart';
import './favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final GetFavoriteVideos getFavoriteVideos;
  final ToggleFavorite toggleFavorite;
  List<VideoFile> _allFavorites = [];
  bool _isInitialized = false;

  FavoritesBloc({
    required this.getFavoriteVideos,
    required this.toggleFavorite,
  }) : super(const FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<RefreshFavorites>(_onRefreshFavorites);
    on<DeleteFavoriteVideo>(_onDeleteFavoriteVideo);
    on<RefreshFromVideoList>(_onRefreshFromVideoList);
    on<InstantRemoveFromFavorites>(_onInstantRemoveFromFavorites);

    // Automatically load favorites when BLoC is created
    add(const LoadFavorites());
  }

  Future<void> _onLoadFavorites(
      LoadFavorites event, Emitter<FavoritesState> emit) async {
    if (_isInitialized) {
      if (_allFavorites.isEmpty) {
        emit(const FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(_allFavorites));
      }
      return;
    }

    emit(const FavoritesLoading());
    try {
      final favorites = await getFavoriteVideos();
      _allFavorites = favorites;
      _isInitialized = true;

      if (favorites.isEmpty) {
        emit(const FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(favorites));
      }
    } catch (e) {
      emit(FavoritesError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onToggleFavorite(
      ToggleFavoriteEvent event, Emitter<FavoritesState> emit) async {
    try {
      // Toggle favorite in repository
      await toggleFavorite(event.videoPath);

      // Refresh favorites list
      final updatedFavorites = await getFavoriteVideos();
      _allFavorites = updatedFavorites;

      if (updatedFavorites.isEmpty) {
        emit(const FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(updatedFavorites));
      }
    } catch (e) {
      emit(FavoritesError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onRefreshFavorites(
      RefreshFavorites event, Emitter<FavoritesState> emit) async {
    _isInitialized = false;
    _allFavorites = [];

    // Clear repository cache to ensure fresh data
    final repo = getFavoriteVideos.repository;
    if (repo is VideoRepositoryImpl) {
      await repo.refreshCache();
    }

    add(const LoadFavorites());
  }

  Future<void> _onDeleteFavoriteVideo(
      DeleteFavoriteVideo event, Emitter<FavoritesState> emit) async {
    try {
      debugPrint(
          'FavoritesBloc: Attempting to delete video: ${event.videoPath}');

      // Find the video to delete
      final videoIndex =
          _allFavorites.indexWhere((v) => v.path == event.videoPath);
      if (videoIndex == -1) {
        debugPrint(
            'FavoritesBloc: Video not found in favorites: ${event.videoPath}');
        return;
      }

      debugPrint('FavoritesBloc: Found video at index $videoIndex');

      // Delete from repository (this will delete the file and metadata)
      final repository = getFavoriteVideos.repository;
      await repository.deleteVideo(event.videoPath);
      debugPrint('FavoritesBloc: Successfully deleted video from repository');

      // Remove from local favorites list
      _allFavorites.removeAt(videoIndex);
      debugPrint(
          'FavoritesBloc: Removed video from favorites list, new count: ${_allFavorites.length}');

      // Emit updated state
      if (_allFavorites.isEmpty) {
        emit(const FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(List<VideoFile>.from(_allFavorites)));
      }
      debugPrint(
          'FavoritesBloc: Emitted new state with ${_allFavorites.length} favorites');

      // Clear repository cache to ensure other screens get updated data
      final repo = getFavoriteVideos.repository;
      if (repo is VideoRepositoryImpl) {
        await repo.refreshCache();
      }

      // Instantly notify video list bloc to remove this video
      BlocCommunicationService.notifyVideoListOfDeletion(event.videoPath);
    } catch (e) {
      debugPrint('FavoritesBloc: Error deleting video: $e');

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

      emit(FavoritesError(errorMessage));
    }
  }

  Future<void> _onRefreshFromVideoList(
      RefreshFromVideoList event, Emitter<FavoritesState> emit) async {
    debugPrint('FavoritesBloc: Refreshing from video list deletion');

    // Clear cache and reload favorites
    final repo = getFavoriteVideos.repository;
    if (repo is VideoRepositoryImpl) {
      await repo.refreshCache();
    }

    // Force reload favorites
    _isInitialized = false;
    _allFavorites = [];
    add(const LoadFavorites());
  }

  Future<void> _onInstantRemoveFromFavorites(
      InstantRemoveFromFavorites event, Emitter<FavoritesState> emit) async {
    debugPrint('FavoritesBloc: Instantly removing video: ${event.videoPath}');

    // Find and remove the video from local favorites list
    final videoIndex =
        _allFavorites.indexWhere((v) => v.path == event.videoPath);
    if (videoIndex != -1) {
      _allFavorites.removeAt(videoIndex);
      debugPrint(
          'FavoritesBloc: Instantly removed video from favorites, new count: ${_allFavorites.length}');

      // Emit updated state immediately
      if (_allFavorites.isEmpty) {
        emit(const FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(List<VideoFile>.from(_allFavorites)));
      }
      debugPrint(
          'FavoritesBloc: Instantly emitted new state with ${_allFavorites.length} favorites');
    }
  }

  // Static create method for simplified DI
  static FavoritesBloc create() {
    final videoLocalDataSource = VideoLocalDataSourceImpl();
    final videoRepository =
        VideoRepositoryImpl(localDataSource: videoLocalDataSource);
    final getFavoriteVideosUseCase = GetFavoriteVideos(videoRepository);
    final toggleFavoriteUseCase = ToggleFavorite(videoRepository);

    return FavoritesBloc(
      getFavoriteVideos: getFavoriteVideosUseCase,
      toggleFavorite: toggleFavoriteUseCase,
    );
  }
}
