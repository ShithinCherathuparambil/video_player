import 'package:flutter/material.dart';

class AppThemes {
  static const Color _primaryColor = Color(0xFF2196F3);
  static const Color _secondaryColor = Color(0xFF03A9F4);
  static const Color _accentColor = Color(0xFF00BCD4);
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1E1E1E);
  static const Color _errorColor = Color(0xFFCF6679);

  // Light theme gradient colors (softer version of the splash gradient)
  static const List<Color> lightGradientColors = [
    Color(0xFFE8E2F0), // Very light purple
    Color(0xFFF0E6F7), // Light purple-pink
    Color(0xFFFCE4EC), // Light pink
    Color(0xFFFFF3E0), // Light orange
    Color(0xFFFFF8E1), // Very light yellow
  ];

  // Original splash gradient colors for accent elements
  static const List<Color> accentGradientColors = [
    Color(0xFF6A4C93), // Purple
    Color(0xFF8E44AD), // Purple-Pink
    Color(0xFFE91E63), // Pink
    Color(0xFFFF6B35), // Orange-Red
    Color(0xFFFFB347), // Orange-Yellow
  ];

  /// Light theme gradient for backgrounds
  static const LinearGradient lightThemeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: lightGradientColors,
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Accent gradient for buttons and highlights
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: accentGradientColors,
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      background: _backgroundColor,
      surface: _surfaceColor,
      error: _errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _backgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    scaffoldBackgroundColor: _backgroundColor,
    cardTheme: const CardThemeData(
      color: _surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: _surfaceColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _secondaryColor,
      tertiary: _accentColor,
      surface: Colors.white,
      error: _errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    iconTheme: const IconThemeData(
      color: Colors.black87,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: Colors.black87,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: Colors.black54,
        fontSize: 14,
      ),
    ),
  );
}
