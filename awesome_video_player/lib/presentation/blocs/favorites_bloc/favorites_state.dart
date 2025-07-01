import 'package:equatable/equatable.dart';
import 'package:lumeo/domain/entities/video_file.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  final List<VideoFile> favorites;
  final DateTime timestamp;

  FavoritesLoaded(this.favorites, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [favorites, timestamp];
}

class FavoritesEmpty extends FavoritesState {
  const FavoritesEmpty();
}

class FavoritesError extends FavoritesState {
  final String message;

  const FavoritesError(this.message);

  @override
  List<Object?> get props => [message];
}
