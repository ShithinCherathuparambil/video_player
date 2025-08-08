import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {
  const LoadFavorites();
}

class ToggleFavoriteEvent extends FavoritesEvent {
  final String videoPath;

  const ToggleFavoriteEvent(this.videoPath);

  @override
  List<Object?> get props => [videoPath];
}

class RefreshFavorites extends FavoritesEvent {
  const RefreshFavorites();
}

class DeleteFavoriteVideo extends FavoritesEvent {
  final String videoPath;

  const DeleteFavoriteVideo(this.videoPath);

  @override
  List<Object?> get props => [videoPath];
}

class RefreshFromVideoList extends FavoritesEvent {
  const RefreshFromVideoList();

  @override
  List<Object?> get props => [];
}

class InstantRemoveFromFavorites extends FavoritesEvent {
  final String videoPath;

  const InstantRemoveFromFavorites(this.videoPath);

  @override
  List<Object?> get props => [videoPath];
}

class SearchFavorites extends FavoritesEvent {
  final String query;

  const SearchFavorites(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleViewMode extends FavoritesEvent {
  const ToggleViewMode();
}

class DeleteMultipleFavorites extends FavoritesEvent {
  final List<String> videoPaths;

  const DeleteMultipleFavorites(this.videoPaths);

  @override
  List<Object?> get props => [videoPaths];
}
