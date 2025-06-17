import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    // Use colorScheme for more detailed color control if needed
    // colorScheme: ColorScheme.light(
    //   primary: Colors.blue,
    //   secondary: Colors.amber,
    //   // ... other colors
    // ),
    // You can customize other theme properties like typography, button themes, etc.
    appBarTheme: const AppBarTheme(
      elevation: 1.0,
      // color: Colors.white, // Example: specific app bar color for light theme
      // iconTheme: IconThemeData(color: Colors.black), // Example
    ),
    // ... other theme properties
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey, // A different swatch for dark theme
    // colorScheme: ColorScheme.dark(
    //   primary: Colors.blueGrey[700]!,
    //   secondary: Colors.tealAccent,
    //   // ... other colors
    // ),
    scaffoldBackgroundColor: Colors.grey[850], // Example dark background
    appBarTheme: AppBarTheme(
      elevation: 1.0,
      color: Colors.grey[900], // Example: specific app bar color for dark theme
      // iconTheme: IconThemeData(color: Colors.white), // Example
    ),
    // Consider cardColor, dialogBackgroundColor, etc.
    // ... other theme properties
  );
}
