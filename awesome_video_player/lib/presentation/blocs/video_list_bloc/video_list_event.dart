import 'package:equatable/equatable.dart';

abstract class VideoListEvent extends Equatable {
  const VideoListEvent();

  @override
  List<Object> get props => [];
}

class LoadVideos extends VideoListEvent {}

// Future: Add events like RefreshVideos, FilterVideos, etc.
// class RefreshVideos extends VideoListEvent {}
// class FilterVideos extends VideoListEvent {
//   final String query;
//   const FilterVideos(this.query);
//   @override
//   List<Object> get props => [query];
// }
