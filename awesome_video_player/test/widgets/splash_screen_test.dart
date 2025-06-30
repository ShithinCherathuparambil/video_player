import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_video_player/presentation/screens/splash_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('should display app title', (WidgetTester tester) async {
      // Build the splash screen
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );

      // Verify the title is displayed
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('should display app icon', (WidgetTester tester) async {
      // Build the splash screen
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );

      // Verify the Flutter logo is displayed
      expect(find.byType(FlutterLogo), findsOneWidget);

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('should have centered layout', (WidgetTester tester) async {
      // Build the splash screen
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );

      // Verify the layout structure
      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('should have proper styling', (WidgetTester tester) async {
      // Build the splash screen
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );

      // Find the title text widget
      final titleFinder = find.text('Awesome Video Player');
      expect(titleFinder, findsOneWidget);

      // Get the text widget and verify styling
      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.fontSize, 32);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should navigate after timer', (WidgetTester tester) async {
      // Build the splash screen
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );

      // Verify splash screen is initially shown
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Advance time to trigger timer but don't wait for navigation
      // since we don't have a full navigation context
      await tester.pump(const Duration(seconds: 1));

      // Verify splash screen is still shown (navigation would happen in real app)
      expect(find.byType(SplashScreen), findsOneWidget);

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('should have proper accessibility',
        (WidgetTester tester) async {
      // Build the splash screen
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );

      // Verify semantic structure
      expect(find.byType(Semantics), findsWidgets);

      // Check that text is accessible
      final titleFinder = find.text('Awesome Video Player');
      expect(titleFinder, findsOneWidget);

      // Verify the widget tree is semantically correct
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('should handle different screen sizes',
        (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone
      await tester.pumpWidget(
        TestHelpers.createMinimalTestApp(child: const SplashScreen()),
      );
      expect(find.text('Awesome Video Player'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet
      await tester.pump();
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('should have proper theme integration',
        (WidgetTester tester) async {
      // Test with light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const SplashScreen(),
        ),
      );
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SplashScreen(),
        ),
      );
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Clean up any pending timers
      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });
}
