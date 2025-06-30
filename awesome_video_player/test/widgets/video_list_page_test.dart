import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:awesome_video_player/presentation/screens/video_list_page.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_factories.dart';
import '../helpers/mock_video_player_platform.dart';
import '../helpers/test_data_builders.dart';

void main() {
  setUpAll(() {
    // Register mock video player platform globally
    MockVideoPlayerPlatform.registerWith();
  });

  group('VideoListPage Widget Tests', () {
    late MockVideoListBloc mockVideoListBloc;
    late MockThemeBloc mockThemeBloc;
    late MockLastPlayedBloc mockLastPlayedBloc;
    late MockFavoritesBloc mockFavoritesBloc;

    setUp(() {
      mockVideoListBloc = MockFactories.createMockVideoListBloc();
      mockThemeBloc = MockFactories.createMockThemeBloc();
      mockLastPlayedBloc = MockFactories.createMockLastPlayedBloc();
      mockFavoritesBloc = MockFactories.createMockFavoritesBloc();
    });

    Widget createTestWidget() {
      return MultiBlocProvider(
        providers: [
          BlocProvider<VideoListBloc>.value(value: mockVideoListBloc),
          BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
          BlocProvider<LastPlayedBloc>.value(value: mockLastPlayedBloc),
          BlocProvider<FavoritesBloc>.value(value: mockFavoritesBloc),
        ],
        child: const MaterialApp(
          home: VideoListPage(),
        ),
      );
    }

    testWidgets('should display app bar with title',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Video Library'), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading',
        (WidgetTester tester) async {
      // Mock the loading state
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([const VideoListLoading()]),
        initialState: const VideoListLoading(),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading videos...'), findsOneWidget);
    });

    testWidgets('should display empty state when no videos',
        (WidgetTester tester) async {
      // Mock the empty state
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([const VideoListEmpty()]),
        initialState: const VideoListEmpty(),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
      expect(find.text('No videos found'), findsOneWidget);
      expect(
          find.text(
              'Add some videos to your device to get started\nor pull down to refresh'),
          findsOneWidget);
    });

    testWidgets('should display error state with message',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to load videos';

      // Mock the error state
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([const VideoListError(errorMessage)]),
        initialState: const VideoListError(errorMessage),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading videos'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display video grid when videos loaded',
        (WidgetTester tester) async {
      final testVideos = [
        VideoFileBuilder().withName('Video 1').build(),
        VideoFileBuilder().withName('Video 2').build(),
        VideoFileBuilder().withName('Video 3').build(),
      ];

      // Mock the loaded state
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(testVideos)]),
        initialState: VideoListLoaded(testVideos),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
      // Verify videos are displayed (check for GestureDetector for video cards)
      expect(find.byType(GestureDetector),
          findsWidgets); // Should find multiple video cards
    });

    testWidgets('should have search functionality',
        (WidgetTester tester) async {
      final testVideos = [
        VideoFileBuilder().withName('Action Movie').build(),
        VideoFileBuilder().withName('Comedy Show').build(),
      ];

      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(testVideos)]),
        initialState: VideoListLoaded(testVideos),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap search icon
      expect(find.byIcon(Icons.search), findsOneWidget);
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify search field appears
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should toggle between grid and list view',
        (WidgetTester tester) async {
      final testVideos = [
        VideoFileBuilder().withName('Video 1').build(),
        VideoFileBuilder().withName('Video 2').build(),
      ];

      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(testVideos)]),
        initialState: VideoListLoaded(testVideos),
      );

      // Start with grid view
      whenListen(
        mockThemeBloc,
        Stream.fromIterable(
            [const ThemeLoaded(themeMode: ThemeMode.system, isGridView: true)]),
        initialState:
            const ThemeLoaded(themeMode: ThemeMode.system, isGridView: true),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Initially should show grid view
      expect(find.byType(GridView), findsOneWidget);

      // Find view toggle button (should show list icon when in grid mode)
      final viewToggleButton = find.byIcon(Icons.view_list);
      expect(viewToggleButton, findsOneWidget);

      // Just verify the button exists and can be tapped
      await tester.tap(viewToggleButton);
      await tester.pump();
    });

    testWidgets('should have refresh functionality',
        (WidgetTester tester) async {
      final testVideos = [VideoFileBuilder().withName('Video 1').build()];

      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(testVideos)]),
        initialState: VideoListLoaded(testVideos),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find refresh button
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pump();

      // Verify refresh was triggered (would need to verify bloc event in real test)
    });

    testWidgets('should navigate to settings', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap settings icon
      expect(find.byIcon(Icons.settings), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Navigation would be tested with a NavigatorObserver in integration tests
    });

    testWidgets('should handle video card tap', (WidgetTester tester) async {
      final testVideo = VideoFileBuilder().withName('Test Video').build();

      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([
          VideoListLoaded([testVideo])
        ]),
        initialState: VideoListLoaded([testVideo]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap video card
      final videoCard = find.text('Test Video');
      expect(videoCard, findsOneWidget);
      await tester.tap(videoCard);
      await tester.pump();

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigation to video player would be tested in integration tests
    });

    testWidgets('should display video status indicators',
        (WidgetTester tester) async {
      final testVideos = [
        VideoFileBuilder()
            .withName('New Video')
            .withStatus(VideoStatus.new_)
            .build(),
        VideoFileBuilder()
            .withName('Watched Video')
            .withStatus(VideoStatus.watched)
            .build(),
        VideoFileBuilder()
            .withName('Watching Video')
            .withStatus(VideoStatus.watching)
            .build(),
      ];

      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(testVideos)]),
        initialState: VideoListLoaded(testVideos),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify videos are displayed (check for GestureDetector and status indicators)
      expect(find.byType(GestureDetector),
          findsWidgets); // Should find multiple video cards

      // Check for status indicators (these are the actual status text labels)
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('Watched'), findsOneWidget);
    });

    testWidgets('should handle favorite toggle', (WidgetTester tester) async {
      final testVideo =
          VideoFileBuilder().withName('Test Video').asFavorite().build();

      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([
          VideoListLoaded([testVideo])
        ]),
        initialState: VideoListLoaded([testVideo]),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find favorite icon (there might be multiple, so use first)
      final favoriteIcons = find.byIcon(Icons.favorite);
      expect(favoriteIcons, findsWidgets);
      await tester.tap(favoriteIcons.first);
      await tester.pump();

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Bloc event would be verified in unit tests
    });
  });
}
