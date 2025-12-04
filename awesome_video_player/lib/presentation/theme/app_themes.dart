import 'package:flutter/material.dart';

class AppThemes {
  // Black & Silver palette
  static const Color primaryColor = Color(0xFFC0C0C0); // Silver
  static const Color secondaryColor = Color(0xFFFFD700); // Gold
  static const Color accentColor = Color(0xFFE0E0E0); // Light silver
  static const Color backgroundColor = Color(0xFF000000); // Pure black
  // static const Color _surfaceColor = Color(0xFF121212); // Near-black surface
  static const Color errorColor = Color(0xFFCF6679);

  // Light theme gradient colors (black & silver)
  static const List<Color> lightGradientColors = [
    Color(0xFF000000), // Black
    Color(0xFF1A1A1A), // Dark grey
    Color(0xFF2C2C2C), // Mid grey
    Color(0xFF4F4F4F), // Silver-grey
    Color(0xFFC0C0C0), // Silver
  ];

  // Accent gradient colors (silver highlight)
  static const List<Color> accentGradientColors = [
    Color(0xFFB0B0B0),
    Color(0xFFC0C0C0),
    Color(0xFFD8D8D8),
    Color(0xFFF0F0F0),
    Color(0xFFFFFFFF),
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
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: backgroundColor,
      surface: backgroundColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: const CardThemeData(
      color: backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: backgroundColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    iconTheme: const IconThemeData(
      color: secondaryColor, // gold icons
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor, // gold
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor, // gold text
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: const BorderSide(color: secondaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(secondaryColor),
      trackColor: WidgetStatePropertyAll(Color(0x66FFD700)), // translucent gold
    ),
    checkboxTheme: const CheckboxThemeData(
      fillColor: WidgetStatePropertyAll(secondaryColor),
      checkColor: WidgetStatePropertyAll(Colors.black),
      side: BorderSide(color: secondaryColor),
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(secondaryColor),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: secondaryColor,
      inactiveTrackColor: Colors.white24,
      thumbColor: secondaryColor,
      overlayColor: Color(0x33FFD700),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: secondaryColor, width: 1.5),
      ),
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: backgroundColor,
      surface: backgroundColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: const CardThemeData(
      color: backgroundColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: backgroundColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    iconTheme: const IconThemeData(
      color: secondaryColor,
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
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        side: const BorderSide(color: secondaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(secondaryColor),
      trackColor: WidgetStatePropertyAll(Color(0x66FFD700)),
    ),
    checkboxTheme: const CheckboxThemeData(
      fillColor: WidgetStatePropertyAll(secondaryColor),
      checkColor: WidgetStatePropertyAll(Colors.black),
      side: BorderSide(color: secondaryColor),
    ),
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(secondaryColor),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: secondaryColor,
      inactiveTrackColor: Colors.white24,
      thumbColor: secondaryColor,
      overlayColor: Color(0x33FFD700),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: secondaryColor, width: 1.5),
      ),
    ),
  );
}
