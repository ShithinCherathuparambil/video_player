import 'package:equatable/equatable.dart';

abstract class VideoPlayerControlsState extends Equatable {
  final bool areControlsVisible;

  const VideoPlayerControlsState(this.areControlsVisible);

  @override
  List<Object> get props => [areControlsVisible];
}

class VideoPlayerControlsVisibilityChanged extends VideoPlayerControlsState {
  const VideoPlayerControlsVisibilityChanged(super.areControlsVisible);
}

// Optionally, if you want to distinguish initial state:
// class VideoPlayerControlsInitial extends VideoPlayerControlsState {
//   const VideoPlayerControlsInitial(super.areControlsVisible);
// }
