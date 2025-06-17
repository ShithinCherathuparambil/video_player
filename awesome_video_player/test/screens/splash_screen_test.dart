import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_video_player/presentation/screens/splash_screen.dart';
import 'package:awesome_video_player/presentation/screens/video_list_page.dart';

// A simple mock navigator observer to track navigation events
class MockNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? PushedRoute;
  Route<dynamic>? ReplacedRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    PushedRoute = route;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    ReplacedRoute = newRoute;
  }
}

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('Displays initial UI elements (logo and text)', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      // Check for FlutterLogo
      expect(find.byType(FlutterLogo), findsOneWidget);
      // Check for Text
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Check initial opacity (should be 0.0, then animates to 1.0)
      final AnimatedOpacity animatedOpacity = tester.widget(find.byType(AnimatedOpacity));
      expect(animatedOpacity.opacity, 0.0);

      // Pump a frame to start animation
      await tester.pump(const Duration(milliseconds: 300)); // Timer in initState for opacity
      await tester.pump(const Duration(milliseconds: 100)); // Start of animation

      final AnimatedOpacity animatedOpacityAfterAnimationStart = tester.widget(find.byType(AnimatedOpacity));
      expect(animatedOpacityAfterAnimationStart.opacity, 1.0);
    });

    testWidgets('Navigates to VideoListPage after timer', (WidgetTester tester) async {
      final mockObserver = MockNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          home: const SplashScreen(),
          // VideoListPage needs to be a valid route for MaterialPageRoute
          routes: {
            '/video_list': (_) => const VideoListPage(),
          },
          navigatorObservers: [mockObserver],
        ),
      );

      // Initial state: SplashScreen is visible
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(VideoListPage), findsNothing);

      // Fast-forward the timers
      // Timer 1: Opacity animation (300ms in SplashScreen initState)
      // Timer 2: Navigation (3 seconds in SplashScreen initState)

      // Pump through the opacity animation timer + a bit for animation itself
      await tester.pump(const Duration(milliseconds: 300)); // opacity timer
      await tester.pump(const Duration(seconds: 2)); // opacity animation duration

      // Now pump through the navigation timer
      await tester.pump(const Duration(seconds: 3)); // Navigation timer
      await tester.pumpAndSettle(); // Allow navigation to complete

      // Verify that VideoListPage is now visible (or that navigation occurred)
      expect(mockObserver.ReplacedRoute, isNotNull);
      expect(mockObserver.ReplacedRoute!.settings.name, isNull); // Navigating by MaterialPageRoute, not named route directly to VideoListPage

      // Check if VideoListPage is now the current screen
      expect(find.byType(VideoListPage), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing); // SplashScreen should be replaced
    });
  });
}
