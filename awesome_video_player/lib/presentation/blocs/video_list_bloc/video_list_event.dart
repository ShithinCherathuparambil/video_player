import 'package:equatable/equatable.dart';
import 'package:lumeo/domain/entities/video_file.dart';

abstract class VideoListEvent extends Equatable {
  const VideoListEvent();

  @override
  List<Object?> get props => [];
}

class LoadVideos extends VideoListEvent {
  final bool forceRefresh;

  const LoadVideos({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class SearchVideos extends VideoListEvent {
  final String query;

  const SearchVideos(this.query);

  @override
  List<Object?> get props => [query];
}

class UpdateVideoStatus extends VideoListEvent {
  final String videoPath;
  final VideoStatus newStatus;
  final Duration? lastPosition;

  const UpdateVideoStatus({
    required this.videoPath,
    required this.newStatus,
    this.lastPosition,
  });

  @override
  List<Object?> get props => [videoPath, newStatus, lastPosition];
}

class ToggleFavorite extends VideoListEvent {
  final String videoPath;

  const ToggleFavorite(this.videoPath);

  @override
  List<Object?> get props => [videoPath];
}

// Future: Add events like RefreshVideos, FilterVideos, etc.
// class RefreshVideos extends VideoListEvent {}
// class FilterVideos extends VideoListEvent {
//   final String query;
//   const FilterVideos(this.query);
//   @override
//   List<Object> get props => [query];
// }
