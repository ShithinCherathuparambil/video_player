import 'package:equatable/equatable.dart';
import 'package:lumeo/domain/entities/video_file.dart';

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
  final bool hasMore;
  final bool isLoadingMore;

  const VideoListLoaded(
    this.videos, {
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object> get props => [videos, hasMore, isLoadingMore];

  VideoListLoaded copyWith({
    List<VideoFile>? videos,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return VideoListLoaded(
      videos ?? this.videos,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class VideoListEmpty extends VideoListState {
  const VideoListEmpty();

  @override
  List<Object> get props => [];
}

class VideoListError extends VideoListState {
  final String message;

  const VideoListError(this.message);

  @override
  List<Object> get props => [message];
}

class VideoListPermissionDenied extends VideoListState {
  final String message;

  const VideoListPermissionDenied(this.message);

  @override
  List<Object> get props => [message];
}
