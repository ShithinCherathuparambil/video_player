import 'package:flutter/material.dart';

class AppThemes {
  static const Color _primaryColor = Color(0xFF2196F3);
  static const Color _secondaryColor = Color(0xFF03A9F4);
  static const Color _accentColor = Color(0xFF00BCD4);
  static const Color _backgroundColor = Color(0xFF121212);
  static const Color _surfaceColor = Color(0xFF1E1E1E);
  static const Color _errorColor = Color(0xFFCF6679);

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
      background: Colors.white,
      surface: Colors.white,
      error: _errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    scaffoldBackgroundColor: Colors.white,
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
