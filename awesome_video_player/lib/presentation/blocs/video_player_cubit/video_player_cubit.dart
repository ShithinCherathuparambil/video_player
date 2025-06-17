import 'package:flutter_bloc/flutter_bloc.dart';
import './video_player_state.dart';

class VideoPlayerCubit extends Cubit<VideoPlayerControlsState> {
  // Initial state: controls are visible
  VideoPlayerCubit() : super(const VideoPlayerControlsVisibilityChanged(true));

  void showControls() {
    if (!state.areControlsVisible) { // Only emit if state actually changes
      emit(const VideoPlayerControlsVisibilityChanged(true));
    }
  }

  void hideControls() {
    if (state.areControlsVisible) { // Only emit if state actually changes
      emit(const VideoPlayerControlsVisibilityChanged(false));
    }
  }

  void toggleControls() {
    emit(VideoPlayerControlsVisibilityChanged(!state.areControlsVisible));
  }
}
