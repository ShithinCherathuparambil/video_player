import 'package:equatable/equatable.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';

abstract class VideoListState extends Equatable {
  const VideoListState();

  @override
  List<Object> get props => [];
}

class VideoListInitial extends VideoListState {}

class VideoListLoading extends VideoListState {}

class VideoListLoaded extends VideoListState {
  final List<VideoFile> videos;

  const VideoListLoaded(this.videos);

  @override
  List<Object> get props => [videos];
}

class VideoListError extends VideoListState {
  final String message;

  const VideoListError(this.message);

  @override
  List<Object> get props => [message];
}

// Specific state for permission denial, if granular handling is desired
class VideoListPermissionDenied extends VideoListState {
  final String message;

  const VideoListPermissionDenied(this.message);

  @override
  List<Object> get props => [message];
}
