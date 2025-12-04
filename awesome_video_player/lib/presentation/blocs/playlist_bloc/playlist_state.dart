import 'package:equatable/equatable.dart';
import 'package:lumeo/domain/entities/video_file.dart';

abstract class PlaylistState extends Equatable {
  const PlaylistState();

  @override
  List<Object?> get props => [];
}

class PlaylistInitial extends PlaylistState {
  const PlaylistInitial();
}

class PlaylistLoaded extends PlaylistState {
  final List<VideoFile> videos;
  final int currentIndex;

  const PlaylistLoaded({
    required this.videos,
    this.currentIndex = 0,
  });

  PlaylistLoaded copyWith({
    List<VideoFile>? videos,
    int? currentIndex,
  }) {
    return PlaylistLoaded(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  VideoFile? get currentVideo {
    if (videos.isEmpty || currentIndex < 0 || currentIndex >= videos.length) {
      return null;
    }
    return videos[currentIndex];
  }

  @override
  List<Object?> get props => [videos, currentIndex];
}

