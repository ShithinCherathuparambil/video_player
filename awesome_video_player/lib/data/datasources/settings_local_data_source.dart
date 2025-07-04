import 'package:flutter/material.dart' show ThemeMode; // For ThemeMode
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
  Future<bool> getGridViewPreference();
  Future<void> saveGridViewPreference(bool isGridView);
  Future<bool> getSubtitlesEnabled();
  Future<void> saveSubtitlesEnabled(bool enabled);
  Future<bool> getAuthenticationEnabled();
  Future<void> saveAuthenticationEnabled(bool enabled);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  // Removed SharedPreferences from constructor
  // final SharedPreferences sharedPreferences;

  static const String _themeModeKey = 'theme_mode';
  static const String _gridViewKey = 'grid_view_preference';
  static const String _subtitlesKey = 'subtitles_enabled';
  static const String _authenticationKey = 'authentication_enabled';

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

  @override
  Future<bool> getGridViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gridViewKey) ?? true; // Default to grid view
  }

  @override
  Future<void> saveGridViewPreference(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridViewKey, isGridView);
  }

  @override
  Future<bool> getSubtitlesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_subtitlesKey) ?? true; // Default to enabled
  }

  @override
  Future<void> saveSubtitlesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subtitlesKey, enabled);
  }

  @override
  Future<bool> getAuthenticationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_authenticationKey) ?? false; // Default to disabled
  }

  @override
  Future<void> saveAuthenticationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authenticationKey, enabled);
  }
}
