import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_video_player/logic/providers/theme_provider.dart'; // Adjust import path as needed

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Needed for SharedPreferences path mocking

  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;
    late Map<String, Object> mockSharedPreferencesValues;

    setUp(() {
      // Initialize with empty/default values before each test
      mockSharedPreferencesValues = {};
      SharedPreferences.setMockInitialValues(mockSharedPreferencesValues);
      themeProvider = ThemeProvider(); // Re-instantiate to ensure fresh state
    });

    test('Initial themeMode should be system if no preference saved', () async {
      // Re-instantiate ThemeProvider to allow its constructor to run _loadThemeMode
      themeProvider = ThemeProvider();
      // Wait for _loadThemeMode to complete if it's async and might not finish before this check
      await Future.delayed(Duration.zero); // Ensure async operations in constructor complete
      expect(themeProvider.themeMode, ThemeMode.system);
      // isDarkMode getter's behavior for ThemeMode.system depends on its implementation.
      // Defaulting to false as per current ThemeProvider.isDarkMode getter.
      expect(themeProvider.isDarkMode, false);
    });

    test('Initial themeMode should load from SharedPreferences (light)', () async {
      SharedPreferences.setMockInitialValues({ThemeProvider.themeModeKey: 'light'});
      themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
    });

    test('Initial themeMode should load from SharedPreferences (dark)', () async {
      SharedPreferences.setMockInitialValues({ThemeProvider.themeModeKey: 'dark'});
      themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);
      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
    });

    test('toggleTheme should switch from light to dark and save to SharedPreferences', () async {
      // Start with light theme explicitly set by saving and reloading
      SharedPreferences.setMockInitialValues({ThemeProvider.themeModeKey: 'light'});
      themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero); // Ensure initial load

      bool listenerCalled = false;
      themeProvider.addListener(() {
        listenerCalled = true;
      });

      await themeProvider.toggleTheme(true); // Toggle to dark

      expect(themeProvider.themeMode, ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
      expect(listenerCalled, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeProvider.themeModeKey), 'dark');
    });

    test('toggleTheme should switch from dark to light and save to SharedPreferences', () async {
      // Start with dark theme explicitly set
      SharedPreferences.setMockInitialValues({ThemeProvider.themeModeKey: 'dark'});
      themeProvider = ThemeProvider();
      await Future.delayed(Duration.zero);

      bool listenerCalled = false;
      themeProvider.addListener(() {
        listenerCalled = true;
      });

      await themeProvider.toggleTheme(false); // Toggle to light

      expect(themeProvider.themeMode, ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
      expect(listenerCalled, true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeProvider.themeModeKey), 'light');
    });

    test('setThemeMode should update themeMode and save to SharedPreferences', () async {
      await themeProvider.setThemeMode(ThemeMode.dark);
      expect(themeProvider.themeMode, ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ThemeProvider.themeModeKey), 'dark');

      await themeProvider.setThemeMode(ThemeMode.light);
      expect(themeProvider.themeMode, ThemeMode.light);
      expect(prefs.getString(ThemeProvider.themeModeKey), 'light');

      await themeProvider.setThemeMode(ThemeMode.system);
      expect(themeProvider.themeMode, ThemeMode.system);
      expect(prefs.getString(ThemeProvider.themeModeKey), 'system');
    });
  });
}
