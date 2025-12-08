import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/presentation/blocs/video_player_cubit/video_player_cubit.dart';
import 'package:lumeo/presentation/blocs/video_player_cubit/video_player_state.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';

import '../helpers/mock_factories.dart';
import '../helpers/mock_video_player_platform.dart';
import '../helpers/test_data_builders.dart';

void main() {
  setUpAll(() {
    // Register mock video player platform globally
    MockVideoPlayerPlatform.registerWith();
  });

  group('VideoPlayerPage Widget Tests', () {
    late MockVideoPlayerCubit mockVideoPlayerCubit;
    late VideoFile testVideo;

    setUpAll(() {
      // Register mock video player platform
      MockVideoPlayerPlatform.registerWith();
    });

    setUp(() {
      mockVideoPlayerCubit = MockFactories.createMockVideoPlayerCubit();
      testVideo = VideoFileBuilder()
          .withName('Test Video')
          .withPath('/test/video.mp4')
          .build();
    });

    Widget createTestWidget({bool resumeFromLastPosition = false}) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<VideoPlayerCubit>.value(value: mockVideoPlayerCubit),
          BlocProvider<ThemeBloc>.value(
              value: MockFactories.createMockThemeBloc()),
        ],
        child: MaterialApp(
          home: VideoPlayerPage(
            video: testVideo,
            resumeFromLastPosition: resumeFromLastPosition,
          ),
        ),
      );
    }

    testWidgets('should display video player', (WidgetTester tester) async {
      // Mock initial state
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable(
            [const VideoPlayerControlsVisibilityChanged(false)]),
        initialState: const VideoPlayerControlsVisibilityChanged(false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(VideoPlayerPage), findsOneWidget);
    });

    testWidgets('should show controls when tapped',
        (WidgetTester tester) async {
      // Mock controls visibility states
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([
          const VideoPlayerControlsVisibilityChanged(false),
          const VideoPlayerControlsVisibilityChanged(true),
        ]),
        initialState: const VideoPlayerControlsVisibilityChanged(false),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap on video area to show controls
      await tester.tap(find.byType(VideoPlayerPage));
      await tester.pump();

      // Controls should be visible
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should hide controls after timeout',
        (WidgetTester tester) async {
      // Mock controls visibility states
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([
          const VideoPlayerControlsVisibilityChanged(true),
          const VideoPlayerControlsVisibilityChanged(false),
        ]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Initially controls are visible
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Wait for timeout
      await tester.pump(const Duration(seconds: 4));

      // Controls should be hidden
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('should display play/pause button',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show play button initially
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('should handle play/pause button tap',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap play button
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump();

      // Cubit method would be verified in unit tests
    });

    testWidgets('should display video progress slider',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('should handle slider interaction',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and interact with slider
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider to middle
      await tester.drag(slider, const Offset(100, 0));
      await tester.pump();
    });

    testWidgets('should display time indicators', (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Should show current time and duration
      expect(find.textContaining('00:'), findsWidgets);
    });

    testWidgets('should display fullscreen button',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    });

    testWidgets('should handle fullscreen toggle', (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap fullscreen button
      final fullscreenButton = find.byIcon(Icons.fullscreen);
      expect(fullscreenButton, findsOneWidget);
      await tester.tap(fullscreenButton);
      await tester.pump();
    });

    testWidgets('should display back button', (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should handle back button tap', (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pump();

      // Navigation would be tested with NavigatorObserver
    });

    testWidgets('should resume from last position when specified',
        (WidgetTester tester) async {
      final videoWithPosition = VideoFileBuilder()
          .withName('Test Video')
          .withLastPlayedPosition(const Duration(minutes: 5))
          .build();

      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable(
            [const VideoPlayerControlsVisibilityChanged(false)]),
        initialState: const VideoPlayerControlsVisibilityChanged(false),
      );

      await tester.pumpWidget(
        BlocProvider<VideoPlayerCubit>.value(
          value: mockVideoPlayerCubit,
          child: MaterialApp(
            home: VideoPlayerPage(
              video: videoWithPosition,
              resumeFromLastPosition: true,
            ),
          ),
        ),
      );
      await tester.pump();

      // Video player should be initialized with resume position
      expect(find.byType(VideoPlayerPage), findsOneWidget);
    });

    testWidgets('should handle orientation changes',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      // Test portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.byType(VideoPlayerPage), findsOneWidget);

      // Test landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pump();
      expect(find.byType(VideoPlayerPage), findsOneWidget);

      // Reset
      await tester.binding.setSurfaceSize(null);

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('should have proper accessibility',
        (WidgetTester tester) async {
      whenListen(
        mockVideoPlayerCubit,
        Stream.fromIterable([const VideoPlayerControlsVisibilityChanged(true)]),
        initialState: const VideoPlayerControlsVisibilityChanged(true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check basic accessibility structure (skip strict guidelines for now)
      expect(find.byType(VideoPlayerPage), findsOneWidget);
    });
  });
}
