import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('AppSettings Entity Tests', () {
    late AppSettings testAppSettings;

    setUp(() {
      testAppSettings = AppSettingsBuilder()
          .withThemeMode(ThemeMode.dark)
          .withGridView(true)
          .withSubtitlesEnabled(true)
          .withVideoDecoder('hardware')
          .withHardwareAcceleration(true)
          .build();
    });

    group('Constructor Tests', () {
      test('should create AppSettings with required parameters', () {
        final appSettings = AppSettings(themeMode: ThemeMode.light);

        expect(appSettings.themeMode, ThemeMode.light);
        expect(appSettings.isGridView, null);
        expect(appSettings.subtitlesEnabled, true); // Default value
        expect(appSettings.videoDecoder, 'auto'); // Default value
        expect(appSettings.hardwareAcceleration, true); // Default value
      });

      test('should create AppSettings with all parameters', () {
        expect(testAppSettings.themeMode, ThemeMode.dark);
        expect(testAppSettings.isGridView, true);
        expect(testAppSettings.subtitlesEnabled, true);
        expect(testAppSettings.videoDecoder, 'hardware');
        expect(testAppSettings.hardwareAcceleration, true);
      });

      test('should create AppSettings with default values', () {
        final appSettings = AppSettings(themeMode: ThemeMode.system);

        expect(appSettings.themeMode, ThemeMode.system);
        expect(appSettings.isGridView, null);
        expect(appSettings.subtitlesEnabled, true);
        expect(appSettings.videoDecoder, 'auto');
        expect(appSettings.hardwareAcceleration, true);
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties are the same', () {
        final appSettings1 = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .withGridView(true)
            .withSubtitlesEnabled(false)
            .build();

        final appSettings2 = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .withGridView(true)
            .withSubtitlesEnabled(false)
            .build();

        expect(appSettings1, equals(appSettings2));
        expect(appSettings1.hashCode, equals(appSettings2.hashCode));
      });

      test('should not be equal when theme modes are different', () {
        final appSettings1 = AppSettingsBuilder()
            .withThemeMode(ThemeMode.light)
            .build();

        final appSettings2 = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .build();

        expect(appSettings1, isNot(equals(appSettings2)));
        expect(appSettings1.hashCode, isNot(equals(appSettings2.hashCode)));
      });

      test('should not be equal when grid view preferences are different', () {
        final appSettings1 = AppSettingsBuilder()
            .withGridView(true)
            .build();

        final appSettings2 = AppSettingsBuilder()
            .withGridView(false)
            .build();

        expect(appSettings1, isNot(equals(appSettings2)));
      });

      test('should not be equal when subtitle preferences are different', () {
        final appSettings1 = AppSettingsBuilder()
            .withSubtitlesEnabled(true)
            .build();

        final appSettings2 = AppSettingsBuilder()
            .withSubtitlesEnabled(false)
            .build();

        expect(appSettings1, isNot(equals(appSettings2)));
      });

      test('should not be equal when video decoder settings are different', () {
        final appSettings1 = AppSettingsBuilder()
            .withVideoDecoder('auto')
            .build();

        final appSettings2 = AppSettingsBuilder()
            .withVideoDecoder('software')
            .build();

        expect(appSettings1, isNot(equals(appSettings2)));
      });

      test('should not be equal when hardware acceleration settings are different', () {
        final appSettings1 = AppSettingsBuilder()
            .withHardwareAcceleration(true)
            .build();

        final appSettings2 = AppSettingsBuilder()
            .withHardwareAcceleration(false)
            .build();

        expect(appSettings1, isNot(equals(appSettings2)));
      });
    });

    group('CopyWith Tests', () {
      test('should return same object when no parameters provided', () {
        final copiedAppSettings = testAppSettings.copyWith();

        expect(copiedAppSettings, equals(testAppSettings));
        expect(copiedAppSettings.themeMode, testAppSettings.themeMode);
        expect(copiedAppSettings.isGridView, testAppSettings.isGridView);
        expect(copiedAppSettings.subtitlesEnabled, testAppSettings.subtitlesEnabled);
        expect(copiedAppSettings.videoDecoder, testAppSettings.videoDecoder);
        expect(copiedAppSettings.hardwareAcceleration, testAppSettings.hardwareAcceleration);
      });

      test('should update only theme mode', () {
        const newThemeMode = ThemeMode.light;

        final copiedAppSettings = testAppSettings.copyWith(
          themeMode: newThemeMode,
        );

        expect(copiedAppSettings.themeMode, newThemeMode);
        // Other properties should remain the same
        expect(copiedAppSettings.isGridView, testAppSettings.isGridView);
        expect(copiedAppSettings.subtitlesEnabled, testAppSettings.subtitlesEnabled);
        expect(copiedAppSettings.videoDecoder, testAppSettings.videoDecoder);
        expect(copiedAppSettings.hardwareAcceleration, testAppSettings.hardwareAcceleration);
      });

      test('should update only grid view preference', () {
        const newIsGridView = false;

        final copiedAppSettings = testAppSettings.copyWith(
          isGridView: newIsGridView,
        );

        expect(copiedAppSettings.isGridView, newIsGridView);
        // Other properties should remain the same
        expect(copiedAppSettings.themeMode, testAppSettings.themeMode);
        expect(copiedAppSettings.subtitlesEnabled, testAppSettings.subtitlesEnabled);
        expect(copiedAppSettings.videoDecoder, testAppSettings.videoDecoder);
        expect(copiedAppSettings.hardwareAcceleration, testAppSettings.hardwareAcceleration);
      });

      test('should update multiple properties', () {
        const newThemeMode = ThemeMode.system;
        const newSubtitlesEnabled = false;
        const newVideoDecoder = 'software';

        final copiedAppSettings = testAppSettings.copyWith(
          themeMode: newThemeMode,
          subtitlesEnabled: newSubtitlesEnabled,
          videoDecoder: newVideoDecoder,
        );

        expect(copiedAppSettings.themeMode, newThemeMode);
        expect(copiedAppSettings.subtitlesEnabled, newSubtitlesEnabled);
        expect(copiedAppSettings.videoDecoder, newVideoDecoder);
        // Unchanged properties
        expect(copiedAppSettings.isGridView, testAppSettings.isGridView);
        expect(copiedAppSettings.hardwareAcceleration, testAppSettings.hardwareAcceleration);
      });

      test('should update all properties', () {
        const newThemeMode = ThemeMode.system;
        const newIsGridView = false;
        const newSubtitlesEnabled = false;
        const newVideoDecoder = 'software';
        const newHardwareAcceleration = false;

        final copiedAppSettings = testAppSettings.copyWith(
          themeMode: newThemeMode,
          isGridView: newIsGridView,
          subtitlesEnabled: newSubtitlesEnabled,
          videoDecoder: newVideoDecoder,
          hardwareAcceleration: newHardwareAcceleration,
        );

        expect(copiedAppSettings.themeMode, newThemeMode);
        expect(copiedAppSettings.isGridView, newIsGridView);
        expect(copiedAppSettings.subtitlesEnabled, newSubtitlesEnabled);
        expect(copiedAppSettings.videoDecoder, newVideoDecoder);
        expect(copiedAppSettings.hardwareAcceleration, newHardwareAcceleration);
      });
    });

    group('Builder Pattern Tests', () {
      test('should build with light theme', () {
        final appSettings = AppSettingsBuilder()
            .asLightTheme()
            .build();

        expect(appSettings.themeMode, ThemeMode.light);
      });

      test('should build with dark theme', () {
        final appSettings = AppSettingsBuilder()
            .asDarkTheme()
            .build();

        expect(appSettings.themeMode, ThemeMode.dark);
      });

      test('should build with system theme', () {
        final appSettings = AppSettingsBuilder()
            .asSystemTheme()
            .build();

        expect(appSettings.themeMode, ThemeMode.system);
      });

      test('should build with list view', () {
        final appSettings = AppSettingsBuilder()
            .withListView()
            .build();

        expect(appSettings.isGridView, false);
      });

      test('should build with grid view enabled', () {
        final appSettings = AppSettingsBuilder()
            .withGridViewEnabled()
            .build();

        expect(appSettings.isGridView, true);
      });
    });

    group('Business Logic Tests', () {
      test('should handle theme mode changes correctly', () {
        final lightSettings = AppSettingsBuilder().asLightTheme().build();
        final darkSettings = AppSettingsBuilder().asDarkTheme().build();
        final systemSettings = AppSettingsBuilder().asSystemTheme().build();

        expect(lightSettings.themeMode, ThemeMode.light);
        expect(darkSettings.themeMode, ThemeMode.dark);
        expect(systemSettings.themeMode, ThemeMode.system);
      });

      test('should handle view mode preferences correctly', () {
        final gridViewSettings = AppSettingsBuilder().withGridViewEnabled().build();
        final listViewSettings = AppSettingsBuilder().withListView().build();

        expect(gridViewSettings.isGridView, true);
        expect(listViewSettings.isGridView, false);
      });

      test('should handle subtitle preferences correctly', () {
        final subtitlesEnabledSettings = AppSettingsBuilder()
            .withSubtitlesEnabled(true)
            .build();
        final subtitlesDisabledSettings = AppSettingsBuilder()
            .withSubtitlesEnabled(false)
            .build();

        expect(subtitlesEnabledSettings.subtitlesEnabled, true);
        expect(subtitlesDisabledSettings.subtitlesEnabled, false);
      });

      test('should handle video decoder preferences correctly', () {
        final autoDecoderSettings = AppSettingsBuilder()
            .withVideoDecoder('auto')
            .build();
        final hardwareDecoderSettings = AppSettingsBuilder()
            .withVideoDecoder('hardware')
            .build();
        final softwareDecoderSettings = AppSettingsBuilder()
            .withVideoDecoder('software')
            .build();

        expect(autoDecoderSettings.videoDecoder, 'auto');
        expect(hardwareDecoderSettings.videoDecoder, 'hardware');
        expect(softwareDecoderSettings.videoDecoder, 'software');
      });

      test('should handle hardware acceleration preferences correctly', () {
        final hardwareAccelerationEnabledSettings = AppSettingsBuilder()
            .withHardwareAcceleration(true)
            .build();
        final hardwareAccelerationDisabledSettings = AppSettingsBuilder()
            .withHardwareAcceleration(false)
            .build();

        expect(hardwareAccelerationEnabledSettings.hardwareAcceleration, true);
        expect(hardwareAccelerationDisabledSettings.hardwareAcceleration, false);
      });
    });

    group('Edge Cases Tests', () {
      test('should handle null grid view preference', () {
        final appSettings = AppSettings(
          themeMode: ThemeMode.system,
          isGridView: null,
        );

        expect(appSettings.isGridView, null);
      });

      test('should maintain consistency between related settings', () {
        final settings = AppSettingsBuilder()
            .withVideoDecoder('software')
            .withHardwareAcceleration(false)
            .build();

        // When using software decoder, hardware acceleration should typically be false
        expect(settings.videoDecoder, 'software');
        expect(settings.hardwareAcceleration, false);
      });
    });
  });
}
