import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added
import 'package:lumeo/presentation/screens/splash_screen.dart';
import 'package:lumeo/presentation/screens/video_list_page.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart'; // Added
import 'package:lumeo/presentation/theme/app_themes.dart'; // Added for MaterialApp theming

// A simple mock navigator observer to track navigation events
class MockNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? pushedRoute; // Renamed for clarity
  Route<dynamic>? replacedRoute; // Renamed for clarity

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoute = route;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedRoute = newRoute;
  }
}

void main() {
  // Needed for SharedPreferences mocking in ThemeBloc's dependencies if real BLoCs are used
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // If ThemeBloc's deps (use cases -> repo -> data source) need SharedPreferences, mock it here.
    // This was done in theme_provider_test.dart and settings_page_test.dart.
    // Since ThemeBloc.create() instantiates the chain, and SettingsLocalDataSourceImpl (used by it)
    // now fetches SharedPreferences internally, this should be okay for the real ThemeBloc.
    // SharedPreferences.setMockInitialValues({}); // Already handled by ThemeBloc tests if run together, ensure it's fine here too.
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('Displays initial UI elements (play icon and text)',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.text('Awesome Video Player'), findsOneWidget);

      final AnimatedOpacity animatedOpacity =
          tester.widget(find.byType(AnimatedOpacity));
      expect(animatedOpacity.opacity, 0.0);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 100));

      final AnimatedOpacity animatedOpacityAfterAnimationStart =
          tester.widget(find.byType(AnimatedOpacity));
      expect(animatedOpacityAfterAnimationStart.opacity, 1.0);
    });

    testWidgets('Navigates to VideoListPage after timer with BLoC providers',
        (WidgetTester tester) async {
      final mockObserver = MockNavigatorObserver();

      // It's important that the MaterialApp providing context for SplashScreen
      // also provides ThemeBloc if SplashScreen or its descendants (like VideoListPage via navigation)
      // might need it. However, SplashScreen itself doesn't.
      // The critical part is that the MaterialApp used for testing the navigation
      // must be able to build VideoListPage correctly.

      await tester.pumpWidget(MultiBlocProvider(
        // Provide ThemeBloc at a level that VideoListPage can access via MaterialApp's context
        providers: [
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc.create(),
          ),
          // VideoListBloc will be provided within VideoListPage itself in its own test.
          // For navigation test, VideoListPage needs to be wrapped if it expects BlocProvider higher up.
          // VideoListPage now provides its own VideoListBloc. So this might not be needed here.
          // Let's check VideoListPage structure: it uses BlocProvider internally.
        ],
        child: MaterialApp(
          // This MaterialApp is for the test environment
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          // themeMode will be picked up by ThemeBloc if MaterialApp is rebuilt by a BlocBuilder,
          // which it is in the actual app's main.dart. For this test, direct provision is key.
          home: const SplashScreen(),
          routes: {
            // The route for VideoListPage must provide its own BLoCs or inherit them.
            // VideoListPage now has its own BlocProvider for VideoListBloc.
            // It will inherit ThemeBloc from MultiBlocProvider above.
            '/video_list': (context) => const VideoListPage(),
          },
          navigatorObservers: [mockObserver],
        ),
      ));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(VideoListPage), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(mockObserver.replacedRoute, isNotNull);
      // No specific named route for MaterialPageRoute if not specified in its settings.
      // expect(mockObserver.replacedRoute!.settings.name, '/video_list'); // This would only be true if settings: RouteSettings(name: '/video_list') was used in MaterialPageRoute

      expect(find.byType(VideoListPage), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    });
  });
}
