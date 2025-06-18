import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/usecases/get_favorite_videos.dart';
import 'package:awesome_video_player/domain/usecases/toggle_favorite.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';
import 'package:awesome_video_player/data/repositories/video_repository_impl.dart';
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
