import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:lumeo/presentation/blocs/video_player_cubit/video_player_cubit.dart';
import 'package:lumeo/presentation/blocs/video_player_cubit/video_player_state.dart';

void main() {
  group('VideoPlayerCubit Tests', () {
    // No complex dependencies to mock for this Cubit

    test('initial state is VideoPlayerControlsVisibilityChanged(true)', () {
      expect(VideoPlayerCubit().state,
          const VideoPlayerControlsVisibilityChanged(true));
    });

    blocTest<VideoPlayerCubit, VideoPlayerControlsState>(
      'emits [VideoPlayerControlsVisibilityChanged(true)] when showControls is called while controls are hidden',
      build: () => VideoPlayerCubit(),
      // Seed initial state if different from constructor, or to test specific transitions
      seed: () => const VideoPlayerControlsVisibilityChanged(false),
      act: (cubit) => cubit.showControls(),
      expect: () => [const VideoPlayerControlsVisibilityChanged(true)],
    );

    blocTest<VideoPlayerCubit, VideoPlayerControlsState>(
      'emits nothing when showControls is called while controls are already visible',
      build: () => VideoPlayerCubit(),
      seed: () =>
          const VideoPlayerControlsVisibilityChanged(true), // Already visible
      act: (cubit) => cubit.showControls(),
      expect: () => [], // Expect no new state if it doesn't change
    );

    blocTest<VideoPlayerCubit, VideoPlayerControlsState>(
      'emits [VideoPlayerControlsVisibilityChanged(false)] when hideControls is called while controls are visible',
      build: () => VideoPlayerCubit(),
      seed: () =>
          const VideoPlayerControlsVisibilityChanged(true), // Start visible
      act: (cubit) => cubit.hideControls(),
      expect: () => [const VideoPlayerControlsVisibilityChanged(false)],
    );

    blocTest<VideoPlayerCubit, VideoPlayerControlsState>(
      'emits nothing when hideControls is called while controls are already hidden',
      build: () => VideoPlayerCubit(),
      seed: () =>
          const VideoPlayerControlsVisibilityChanged(false), // Already hidden
      act: (cubit) => cubit.hideControls(),
      expect: () => [],
    );

    blocTest<VideoPlayerCubit, VideoPlayerControlsState>(
      'emits [VideoPlayerControlsVisibilityChanged(false)] when toggleControls is called while controls are visible',
      build: () => VideoPlayerCubit(),
      seed: () =>
          const VideoPlayerControlsVisibilityChanged(true), // Start visible
      act: (cubit) => cubit.toggleControls(),
      expect: () => [const VideoPlayerControlsVisibilityChanged(false)],
    );

    blocTest<VideoPlayerCubit, VideoPlayerControlsState>(
      'emits [VideoPlayerControlsVisibilityChanged(true)] when toggleControls is called while controls are hidden',
      build: () => VideoPlayerCubit(),
      seed: () =>
          const VideoPlayerControlsVisibilityChanged(false), // Start hidden
      act: (cubit) => cubit.toggleControls(),
      expect: () => [const VideoPlayerControlsVisibilityChanged(true)],
    );
  });
}
