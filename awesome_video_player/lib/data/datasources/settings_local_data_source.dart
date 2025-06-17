import 'package:flutter/material.dart' show ThemeMode; // For ThemeMode
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  // Removed SharedPreferences from constructor
  // final SharedPreferences sharedPreferences;

  static const String _themeModeKey = 'theme_mode';

  // Constructor no longer requires SharedPreferences
  SettingsLocalDataSourceImpl();

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance(); // Get instance here
    final themeModeString = prefs.getString(_themeModeKey);
    if (themeModeString == 'light') {
      return ThemeMode.light;
    } else if (themeModeString == 'dark') {
      return ThemeMode.dark;
    } else {
      return ThemeMode.system; // Default
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance(); // Get instance here
    String themeString = 'system';
    if (mode == ThemeMode.light) themeString = 'light';
    if (mode == ThemeMode.dark) themeString = 'dark';
    await prefs.setString(_themeModeKey, themeString);
  }
}
