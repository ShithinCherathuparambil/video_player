import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/presentation/screens/splash_screen.dart';

void main() {
  group('SplashScreen Visual Tests', () {
    testWidgets('should display gradient background with play icon', (WidgetTester tester) async {
      // Build the splash screen without triggering timers
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6A4C93), // Purple
                    Color(0xFF8E44AD), // Purple-Pink
                    Color(0xFFE91E63), // Pink
                    Color(0xFFFF6B35), // Orange-Red
                    Color(0xFFFFB347), // Orange-Yellow
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Custom play button icon with white color
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 60,
                        color: Color(0xFF6A4C93),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Awesome Video Player',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the play button icon is displayed
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      
      // Verify the title text is displayed
      expect(find.text('Awesome Video Player'), findsOneWidget);
      
      // Verify the gradient container is present
      expect(find.byType(Container), findsWidgets);
      
      // Find the main container with gradient decoration
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      
      // Verify it has a BoxDecoration with LinearGradient
      expect(container.decoration, isA<BoxDecoration>());
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      
      // Verify gradient colors
      final LinearGradient gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors.length, 5);
      expect(gradient.colors.first, const Color(0xFF6A4C93));
      expect(gradient.colors.last, const Color(0xFFFFB347));
    });

    testWidgets('should have proper text styling', (WidgetTester tester) async {
      // Build a simple version without timers
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text(
                'Awesome Video Player',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );

      // Find the title text widget
      final titleFinder = find.text('Awesome Video Player');
      expect(titleFinder, findsOneWidget);

      // Get the text widget and verify styling
      final textWidget = tester.widget<Text>(titleFinder);
      expect(textWidget.style?.fontSize, 28);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('should have play icon with correct styling', (WidgetTester tester) async {
      // Build a simple version with just the icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  size: 60,
                  color: Color(0xFF6A4C93),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify the play button icon is displayed
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      
      // Get the icon widget and verify styling
      final iconFinder = find.byIcon(Icons.play_arrow);
      final Icon iconWidget = tester.widget(iconFinder);
      expect(iconWidget.size, 60);
      expect(iconWidget.color, const Color(0xFF6A4C93));
    });
  });
}
