// Main widget test file for the Awesome Video Player app
// This file contains basic app-level widget tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/main.dart';
import 'package:lumeo/presentation/screens/splash_screen.dart';

void main() {
  group('App Widget Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build our app directly (MyApp already contains MaterialApp)
      await tester.pumpWidget(const MyApp());

      // Verify the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MyApp), findsOneWidget);

      // Clean up any pending timers with shorter timeout
      try {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } catch (e) {
        // If pumpAndSettle times out, just pump a few times
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    });

    testWidgets('App should show splash screen initially',
        (WidgetTester tester) async {
      // Build our app directly
      await tester.pumpWidget(const MyApp());

      // Wait for initial frame
      await tester.pump();

      // Verify splash screen is shown
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Awesome Video Player'), findsOneWidget);

      // Clean up any pending timers with shorter timeout
      try {
        await tester.pumpAndSettle(const Duration(seconds: 2));
      } catch (e) {
        // If pumpAndSettle times out, just pump a few times
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }
    });

    testWidgets('App should have correct title', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(const MyApp());

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify the title
      expect(materialApp.title, 'Awesome Video Player');
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('App should have theme configuration',
        (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(const MyApp());

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify themes are configured
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });
  });
}
