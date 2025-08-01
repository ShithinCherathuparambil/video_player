import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';

void main() {
  group('GradientBackground', () {
    testWidgets('should display light theme gradient in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const GradientBackground(
            child: Text('Test'),
          ),
        ),
      );

      // Find the container with gradient decoration
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      expect(container.decoration, isA<BoxDecoration>());
      
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      
      final LinearGradient gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors, AppThemes.lightGradientColors);
    });

    testWidgets('should display dark background in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const GradientBackground(
            isLightTheme: false,
            child: Text('Test'),
          ),
        ),
      );

      // Find the container with solid color
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      expect(container.decoration, isA<BoxDecoration>());
      
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.color, const Color(0xFF121212));
    });
  });

  group('GradientScaffold', () {
    testWidgets('should create scaffold with gradient background in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const GradientScaffold(
            body: Text('Test Body'),
          ),
        ),
      );

      // Verify scaffold exists
      expect(find.byType(Scaffold), findsOneWidget);
      
      // Verify gradient background container exists
      expect(find.byType(GradientBackground), findsOneWidget);
      
      // Verify body content
      expect(find.text('Test Body'), findsOneWidget);
    });

    testWidgets('should create scaffold with app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: GradientScaffold(
            appBar: AppBar(title: const Text('Test App Bar')),
            body: const Text('Test Body'),
          ),
        ),
      );

      // Verify app bar exists
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test App Bar'), findsOneWidget);
    });
  });

  group('GradientCard', () {
    testWidgets('should display gradient card in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: GradientCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      // Find the card container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      expect(container.decoration, isA<BoxDecoration>());
      
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      expect(decoration.borderRadius, isA<BorderRadius>());
      expect(decoration.boxShadow, isNotNull);
    });

    testWidgets('should use accent gradient when specified', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: GradientCard(
              useAccentGradient: true,
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      // Find the card container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      final LinearGradient gradient = decoration.gradient as LinearGradient;
      
      expect(gradient.colors, AppThemes.accentGradientColors);
    });
  });

  group('GradientButton', () {
    testWidgets('should display gradient button in light theme', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: GradientButton(
              onPressed: () => buttonPressed = true,
              child: const Text('Button Text'),
            ),
          ),
        ),
      );

      // Find the button container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      expect(container.decoration, isA<BoxDecoration>());
      
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());

      // Test button press
      await tester.tap(find.byType(GradientButton));
      expect(buttonPressed, isTrue);
    });

    testWidgets('should display solid color button in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: GradientButton(
              child: Text('Button Text'),
            ),
          ),
        ),
      );

      // Find the button container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      
      expect(decoration.gradient, isNull);
      expect(decoration.color, const Color(0xFF2196F3));
    });
  });
}
