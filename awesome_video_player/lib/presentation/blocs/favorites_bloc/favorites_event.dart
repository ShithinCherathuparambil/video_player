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
