import 'package:flutter/material.dart';

/// Lumeo Color Palette - MX Player-inspired
/// Ultra-modern colors for the next-generation video player
class LumeoColors {
  // Primary Colors - Black & Silver
  static const primary = Color(0xFFC0C0C0); // Silver
  static const primaryDark = Color(0xFF9E9E9E); // Dark silver
  static const primaryLight = Color(0xFFE0E0E0); // Light silver

  // Accent Colors (Silver variations)
  static const neonBlue = Color(0xFFC0C0C0);
  static const neonPurple = Color(0xFFD0D0D0);
  static const neonGreen = Color(0xFFE0E0E0);
  static const neonPink = Color(0xFFF0F0F0);
  static const mxOrange = Color(0xFFB0B0B0);
  static const mxTeal = Color(0xFF8C8C8C);

  // Background Colors
  static const backgroundDark = Color(0xFF000000); // True black (AMOLED)
  static const backgroundCard = Color(0xFF1A1A1A);
  static const backgroundElevated = Color(0xFF2A2A2A);
  static const glassBackground = Color(0x40FFFFFF);

  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textTertiary = Color(0xFF6B7280);

  // Status Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Glassmorphism Colors
  static const glassWhite = Color(0x30FFFFFF);
  static const glassBlack = Color(0x40000000);

  // Gradient Colors (black to silver)
  static const gradientStart = Color(0xFF000000);
  static const gradientEnd = Color(0xFFC0C0C0);

  // MX Player Theme Colors
  static const mxLightBackground = Color(0xFFF5F5F5);
  static const mxLightCard = Color(0xFFFFFFFF);
  static const mxDarkBackground = Color(0xFF121212);
  static const mxDarkCard = Color(0xFF1E1E1E);
  static const mxAmoledBackground = Color(0xFF000000);
  static const mxAmoledCard = Color(0xFF0A0A0A);

  // Get neon color by index
  static Color getNeonColor(int index) {
    final colors = [neonBlue, neonPurple, neonGreen, neonPink, mxOrange, mxTeal];
    return colors[index % colors.length];
  }

  // Get theme colors
  static Map<String, Color> getLightTheme() {
    return {
      'background': mxLightBackground,
      'card': mxLightCard,
      'text': const Color(0xFF1A1A1A),
      'textSecondary': const Color(0xFF6B7280),
    };
  }

  static Map<String, Color> getDarkTheme() {
    return {
      'background': mxDarkBackground,
      'card': mxDarkCard,
      'text': textPrimary,
      'textSecondary': textSecondary,
    };
  }

  static Map<String, Color> getAmoledTheme() {
    return {
      'background': mxAmoledBackground,
      'card': mxAmoledCard,
      'text': textPrimary,
      'textSecondary': textSecondary,
    };
  }

  // Get accent color by name
  static Color getAccentColor(String name) {
    switch (name.toLowerCase()) {
      case 'blue':
        return neonBlue;
      case 'purple':
        return neonPurple;
      case 'green':
        return neonGreen;
      case 'pink':
        return neonPink;
      case 'orange':
        return mxOrange;
      case 'teal':
        return mxTeal;
      default:
        return primary;
    }
  }
}

