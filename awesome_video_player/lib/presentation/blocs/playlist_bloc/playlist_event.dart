import 'package:equatable/equatable.dart';
import 'package:lumeo/domain/entities/video_file.dart';

abstract class PlaylistEvent extends Equatable {
  const PlaylistEvent();

  @override
  List<Object?> get props => [];
}

class LoadPlaylist extends PlaylistEvent {
  final List<VideoFile> videos;

  const LoadPlaylist(this.videos);

  @override
  List<Object?> get props => [videos];
}

class AddToPlaylist extends PlaylistEvent {
  final VideoFile video;

  const AddToPlaylist(this.video);

  @override
  List<Object?> get props => [video];
}

class RemoveFromPlaylist extends PlaylistEvent {
  final String videoPath;

  const RemoveFromPlaylist(this.videoPath);

  @override
  List<Object?> get props => [videoPath];
}

class ReorderPlaylist extends PlaylistEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderPlaylist(this.oldIndex, this.newIndex);

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

class SetCurrentVideo extends PlaylistEvent {
  final int index;

  const SetCurrentVideo(this.index);

  @override
  List<Object?> get props => [index];
}

class PlayNext extends PlaylistEvent {
  const PlayNext();
}

class PlayPrevious extends PlaylistEvent {
  const PlayPrevious();
}

class ShufflePlaylist extends PlaylistEvent {
  const ShufflePlaylist();
}

class ClearPlaylist extends PlaylistEvent {
  const ClearPlaylist();
}

