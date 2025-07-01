import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart'
    as theme_state; // aliased
import 'package:lumeo/presentation/screens/video_list_page.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';
import 'package:mockito/mockito.dart';
// Mock for path_provider and permission_handler are no longer needed here,
// as we will mock the BLoC layer.

// Mock BLoCs
class MockVideoListBloc extends MockBloc<VideoListEvent, VideoListState>
    implements VideoListBloc {}

class MockThemeBloc extends MockBloc<ThemeEvent, theme_state.ThemeState>
    implements ThemeBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVideoListBloc mockVideoListBloc;
  late MockThemeBloc mockThemeBloc;

  setUp(() {
    mockVideoListBloc = MockVideoListBloc();
    mockThemeBloc = MockThemeBloc();

    // Default state for ThemeBloc for SettingsPage navigation to work
    whenListen(
      mockThemeBloc,
      Stream.fromIterable(
          [const theme_state.ThemeLoaded(themeMode: ThemeMode.light)]),
      initialState: const theme_state.ThemeLoaded(themeMode: ThemeMode.light),
    );
  });

  Widget createTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VideoListBloc>.value(value: mockVideoListBloc),
        BlocProvider<ThemeBloc>.value(value: mockThemeBloc),
      ],
      child: MaterialApp(
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        home: child,
        // Need to provide routes if SettingsPage or VideoPlayerPage are pushed by name
        // For direct MaterialPageRoute, this is less critical but good practice.
        routes: const {
          // Define routes if SettingsPage or VideoPlayerPage are pushed by name during tests
          // For now, VideoListPage itself is the 'child'
        },
      ),
    );
  }

  final tVideos = [VideoFile(name: 'video1.mp4', path: '/video1.mp4')];

  group('VideoListPage Widget Tests with MockVideoListBloc', () {
    testWidgets('Displays AppBar and initial state (usually loading)',
        (WidgetTester tester) async {
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListInitial(), VideoListLoading()]),
        initialState: VideoListInitial(),
      );

      await tester.pumpWidget(createTestableWidget(const VideoListPage()));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('My Videos'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // VideoListPage dispatches LoadVideos on init through BlocProvider.create.
      // So, it will quickly move to Loading state.
      await tester.pump(); // Initial pump for BlocProvider create
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays loading indicator for VideoListLoading state',
        (WidgetTester tester) async {
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoading()]),
        initialState: VideoListLoading(),
      );
      await tester.pumpWidget(createTestableWidget(const VideoListPage()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays list of videos for VideoListLoaded state',
        (WidgetTester tester) async {
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(tVideos)]),
        initialState: VideoListLoaded(tVideos),
      );
      await tester.pumpWidget(createTestableWidget(const VideoListPage()));
      await tester.pumpAndSettle(); // Settle animations/list rendering

      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('video1.mp4'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(tVideos.length));
    });

    testWidgets(
        'Displays "No videos found" for VideoListLoaded with empty list and allows retry',
        (WidgetTester tester) async {
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([VideoListLoaded(const [])]),
        initialState: VideoListLoaded(const []),
      );
      await tester.pumpWidget(createTestableWidget(const VideoListPage()));
      await tester.pumpAndSettle();

      expect(find.text('No videos found.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Try Again'), findsOneWidget);

      // Test retry button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
      verify(() => mockVideoListBloc.add(const LoadVideos())).called(1);
    });

    testWidgets(
        'Displays error message for VideoListError state and allows retry',
        (WidgetTester tester) async {
      const errorMessage = 'Failed to load videos';
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable([const VideoListError(errorMessage)]),
        initialState: const VideoListError(errorMessage),
      );
      await tester.pumpWidget(createTestableWidget(const VideoListPage()));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Try Again'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Try Again'));
      verify(() => mockVideoListBloc.add(LoadVideos())).called(1);
    });

    testWidgets(
        'Displays permission denied message for VideoListPermissionDenied state and allows retry',
        (WidgetTester tester) async {
      const permissionMessage = 'Video permission denied';
      whenListen(
        mockVideoListBloc,
        Stream.fromIterable(
            [const VideoListPermissionDenied(permissionMessage)]),
        initialState: const VideoListPermissionDenied(permissionMessage),
      );
      await tester.pumpWidget(createTestableWidget(const VideoListPage()));
      await tester.pumpAndSettle();

      expect(find.text(permissionMessage), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry Permissions / Load'),
          findsOneWidget);

      await tester
          .tap(find.widgetWithText(ElevatedButton, 'Retry Permissions / Load'));
      verify(() => mockVideoListBloc.add(LoadVideos())).called(1);
    });
  });
}
