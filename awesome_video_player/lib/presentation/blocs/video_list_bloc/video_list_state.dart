import 'package:equatable/equatable.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';

abstract class VideoListState extends Equatable {
  const VideoListState();

  @override
  List<Object> get props => [];
}

class VideoListInitial extends VideoListState {
  const VideoListInitial();
}

class VideoListLoading extends VideoListState {
  const VideoListLoading();
}

class VideoListLoaded extends VideoListState {
  final List<VideoFile> videos;
  final DateTime timestamp;

  VideoListLoaded(this.videos, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object> get props => [videos, timestamp];
}

class VideoListEmpty extends VideoListState {
  const VideoListEmpty();
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
