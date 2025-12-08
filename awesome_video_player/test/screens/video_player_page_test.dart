import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aspect Ratio Formatting Tests', () {
    // Test the aspect ratio formatting logic
    String formatAspectRatio(double ratio) {
      // Round to 2 decimal places for display
      final roundedRatio = (ratio * 100).round() / 100;

      // Common aspect ratios with their standard names
      if ((ratio - 16 / 9).abs() < 0.01) return '16:9';
      if ((ratio - 4 / 3).abs() < 0.01) return '4:3';
      if ((ratio - 1 / 1).abs() < 0.01) return '1:1';
      if ((ratio - 21 / 9).abs() < 0.01) return '21:9';
      if ((ratio - 2.35 / 1).abs() < 0.01) return '2.35:1';

      // For other ratios, show the actual ratio
      return '${roundedRatio.toStringAsFixed(2)}:1';
    }

    test('formats common aspect ratios correctly', () {
      // Test common aspect ratios
      expect(formatAspectRatio(16 / 9), equals('16:9'));
      expect(formatAspectRatio(4 / 3), equals('4:3'));
      expect(formatAspectRatio(1 / 1), equals('1:1'));
      expect(formatAspectRatio(21 / 9), equals('21:9'));
      expect(formatAspectRatio(2.35 / 1), equals('2.35:1'));
    });

    test('formats custom aspect ratios correctly', () {
      // Test custom aspect ratios
      expect(formatAspectRatio(1.85), equals('1.85:1'));
      expect(formatAspectRatio(2.39), equals('2.39:1'));
      expect(formatAspectRatio(1.25),
          equals('1.25:1')); // Changed from 1.33 to avoid conflict with 4/3
    });

    test('handles edge cases', () {
      // Test edge cases
      expect(formatAspectRatio(0.5), equals('0.50:1'));
      expect(formatAspectRatio(3.0), equals('3.00:1'));
    });

    test('handles very close to standard ratios', () {
      // Test ratios that are very close to standard ratios
      expect(formatAspectRatio(16 / 9 + 0.001), equals('16:9'));
      expect(formatAspectRatio(4 / 3 - 0.001), equals('4:3'));
      expect(formatAspectRatio(1 / 1 + 0.005), equals('1:1'));
    });
  });

  group('Aspect Ratio Cycling Tests', () {
    test('cycles through aspect ratios correctly', () {
      final List<double> aspectRatios = [
        16 / 9,
        4 / 3,
        1 / 1,
        21 / 9,
        2.35 / 1
      ];

      int currentIndex = 0;

      // Test cycling through ratios
      // First cycle: original -> 16:9 -> 4:3 -> 1:1 -> 21:9 -> 2.35:1 -> original

      // Original aspect ratio (index 0)
      expect(currentIndex, equals(0));

      // Next: 16:9 (index 1)
      currentIndex = (currentIndex + 1) % (aspectRatios.length + 1);
      expect(currentIndex, equals(1));

      // Next: 4:3 (index 2)
      currentIndex = (currentIndex + 1) % (aspectRatios.length + 1);
      expect(currentIndex, equals(2));

      // Next: 1:1 (index 3)
      currentIndex = (currentIndex + 1) % (aspectRatios.length + 1);
      expect(currentIndex, equals(3));

      // Next: 21:9 (index 4)
      currentIndex = (currentIndex + 1) % (aspectRatios.length + 1);
      expect(currentIndex, equals(4));

      // Next: 2.35:1 (index 5)
      currentIndex = (currentIndex + 1) % (aspectRatios.length + 1);
      expect(currentIndex, equals(5));

      // Next: back to original (index 0)
      currentIndex = (currentIndex + 1) % (aspectRatios.length + 1);
      expect(currentIndex, equals(0));
    });

    test('gets correct aspect ratio value for each index', () {
      final List<double> aspectRatios = [
        16 / 9,
        4 / 3,
        1 / 1,
        21 / 9,
        2.35 / 1
      ];
      double originalAspectRatio = 1.85;

      // Test getting the correct aspect ratio for each index
      double getAspectRatio(int index) {
        if (index == 0) {
          return originalAspectRatio;
        } else {
          return aspectRatios[index - 1];
        }
      }

      expect(getAspectRatio(0), equals(originalAspectRatio));
      expect(getAspectRatio(1), equals(16 / 9));
      expect(getAspectRatio(2), equals(4 / 3));
      expect(getAspectRatio(3), equals(1 / 1));
      expect(getAspectRatio(4), equals(21 / 9));
      expect(getAspectRatio(5), equals(2.35 / 1));
    });
  });
}
