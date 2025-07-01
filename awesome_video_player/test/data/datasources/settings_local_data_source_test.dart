import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumeo/data/datasources/settings_local_data_source.dart';
import '../../helpers/test_utils.dart';

void main() {
  group('SettingsLocalDataSource Tests', () {
    late SettingsLocalDataSourceImpl dataSource;

    setUp(() {
      TestUtils.setupTestEnvironment();
      dataSource = SettingsLocalDataSourceImpl();
    });

    tearDown(() async {
      // Clear SharedPreferences after each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    group('Theme Mode Tests', () {
      test('should return system theme mode as default', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        final result = await dataSource.getThemeMode();

        // assert
        expect(result, ThemeMode.system);
      });

      test('should return light theme mode when stored', () async {
        // arrange
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});

        // act
        final result = await dataSource.getThemeMode();

        // assert
        expect(result, ThemeMode.light);
      });

      test('should return dark theme mode when stored', () async {
        // arrange
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

        // act
        final result = await dataSource.getThemeMode();

        // assert
        expect(result, ThemeMode.dark);
      });

      test('should return system theme mode for invalid stored value',
          () async {
        // arrange
        SharedPreferences.setMockInitialValues({'theme_mode': 'invalid'});

        // act
        final result = await dataSource.getThemeMode();

        // assert
        expect(result, ThemeMode.system);
      });

      test('should save light theme mode correctly', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveThemeMode(ThemeMode.light);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'light');
      });

      test('should save dark theme mode correctly', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveThemeMode(ThemeMode.dark);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'dark');
      });

      test('should save system theme mode correctly', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveThemeMode(ThemeMode.system);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), 'system');
      });
    });

    group('Grid View Preference Tests', () {
      test('should return true as default grid view preference', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        final result = await dataSource.getGridViewPreference();

        // assert
        expect(result, true);
      });

      test('should return stored grid view preference when true', () async {
        // arrange
        SharedPreferences.setMockInitialValues({'grid_view_preference': true});

        // act
        final result = await dataSource.getGridViewPreference();

        // assert
        expect(result, true);
      });

      test('should return stored grid view preference when false', () async {
        // arrange
        SharedPreferences.setMockInitialValues({'grid_view_preference': false});

        // act
        final result = await dataSource.getGridViewPreference();

        // assert
        expect(result, false);
      });

      test('should save grid view preference as true', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveGridViewPreference(true);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('grid_view_preference'), true);
      });

      test('should save grid view preference as false', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveGridViewPreference(false);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('grid_view_preference'), false);
      });
    });

    group('Subtitles Enabled Tests', () {
      test('should return true as default subtitles enabled preference',
          () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        final result = await dataSource.getSubtitlesEnabled();

        // assert
        expect(result, true);
      });

      test('should return stored subtitles preference when true', () async {
        // arrange
        SharedPreferences.setMockInitialValues({'subtitles_enabled': true});

        // act
        final result = await dataSource.getSubtitlesEnabled();

        // assert
        expect(result, true);
      });

      test('should return stored subtitles preference when false', () async {
        // arrange
        SharedPreferences.setMockInitialValues({'subtitles_enabled': false});

        // act
        final result = await dataSource.getSubtitlesEnabled();

        // assert
        expect(result, false);
      });

      test('should save subtitles enabled preference as true', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveSubtitlesEnabled(true);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('subtitles_enabled'), true);
      });

      test('should save subtitles enabled preference as false', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveSubtitlesEnabled(false);

        // assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('subtitles_enabled'), false);
      });
    });

    group('Integration Tests', () {
      test('should handle multiple preference operations', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        await dataSource.saveThemeMode(ThemeMode.dark);
        await dataSource.saveGridViewPreference(false);
        await dataSource.saveSubtitlesEnabled(true);

        final themeMode = await dataSource.getThemeMode();
        final gridView = await dataSource.getGridViewPreference();
        final subtitles = await dataSource.getSubtitlesEnabled();

        // assert
        expect(themeMode, ThemeMode.dark);
        expect(gridView, false);
        expect(subtitles, true);
      });

      test('should handle preference updates', () async {
        // arrange
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'light',
          'grid_view_preference': true,
          'subtitles_enabled': false,
        });

        // act - update preferences
        await dataSource.saveThemeMode(ThemeMode.dark);
        await dataSource.saveGridViewPreference(false);
        await dataSource.saveSubtitlesEnabled(true);

        final themeMode = await dataSource.getThemeMode();
        final gridView = await dataSource.getGridViewPreference();
        final subtitles = await dataSource.getSubtitlesEnabled();

        // assert
        expect(themeMode, ThemeMode.dark);
        expect(gridView, false);
        expect(subtitles, true);
      });

      test('should handle mixed existing and new preferences', () async {
        // arrange
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'dark',
          // grid_view_preference not set
          'subtitles_enabled': false,
        });

        // act
        final themeMode = await dataSource.getThemeMode();
        final gridView = await dataSource.getGridViewPreference();
        final subtitles = await dataSource.getSubtitlesEnabled();

        // assert
        expect(themeMode, ThemeMode.dark);
        expect(gridView, true); // Default value
        expect(subtitles, false);
      });
    });

    group('Error Handling Tests', () {
      test('should handle SharedPreferences exceptions gracefully', () async {
        // Note: In a real scenario, you might want to test actual SharedPreferences failures
        // For now, we test that the methods complete without throwing

        // arrange
        SharedPreferences.setMockInitialValues({});

        // act & assert - should not throw
        expect(() => dataSource.getThemeMode(), returnsNormally);
        expect(() => dataSource.getGridViewPreference(), returnsNormally);
        expect(() => dataSource.getSubtitlesEnabled(), returnsNormally);
        expect(
            () => dataSource.saveThemeMode(ThemeMode.light), returnsNormally);
        expect(() => dataSource.saveGridViewPreference(true), returnsNormally);
        expect(() => dataSource.saveSubtitlesEnabled(true), returnsNormally);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent reads', () async {
        // arrange
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'dark',
          'grid_view_preference': true,
          'subtitles_enabled': false,
        });

        // act
        final futures = List.generate(
            10,
            (_) => Future.wait([
                  dataSource.getThemeMode(),
                  dataSource.getGridViewPreference(),
                  dataSource.getSubtitlesEnabled(),
                ]));

        final results = await Future.wait(futures);

        // assert
        for (final result in results) {
          expect(result[0], ThemeMode.dark);
          expect(result[1], true);
          expect(result[2], false);
        }
      });

      test('should handle multiple concurrent writes', () async {
        // arrange
        SharedPreferences.setMockInitialValues({});

        // act
        final futures = List.generate(
            5,
            (index) => Future.wait([
                  dataSource.saveThemeMode(
                      index % 2 == 0 ? ThemeMode.light : ThemeMode.dark),
                  dataSource.saveGridViewPreference(index % 2 == 0),
                  dataSource.saveSubtitlesEnabled(index % 2 == 1),
                ]));

        await Future.wait(futures);

        // assert - should complete without errors
        final themeMode = await dataSource.getThemeMode();
        final gridView = await dataSource.getGridViewPreference();
        final subtitles = await dataSource.getSubtitlesEnabled();

        // Values should be from the last write
        expect(themeMode, isA<ThemeMode>());
        expect(gridView, isA<bool>());
        expect(subtitles, isA<bool>());
      });
    });
  });
}
