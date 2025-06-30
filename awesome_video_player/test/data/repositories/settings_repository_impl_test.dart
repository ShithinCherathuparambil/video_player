import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/data/repositories/settings_repository_impl.dart';
import 'package:awesome_video_player/data/datasources/settings_local_data_source.dart';

import '../../helpers/test_data_builders.dart';

// Manual mock class
class MockSettingsLocalDataSource extends Mock
    implements SettingsLocalDataSource {
  @override
  Future<ThemeMode> getThemeMode() => super.noSuchMethod(
        Invocation.method(#getThemeMode, []),
        returnValue: Future.value(ThemeMode.system),
      );

  @override
  Future<bool> getGridViewPreference() => super.noSuchMethod(
        Invocation.method(#getGridViewPreference, []),
        returnValue: Future.value(true),
      );

  @override
  Future<bool> getSubtitlesEnabled() => super.noSuchMethod(
        Invocation.method(#getSubtitlesEnabled, []),
        returnValue: Future.value(false),
      );

  @override
  Future<void> saveThemeMode(ThemeMode mode) => super.noSuchMethod(
        Invocation.method(#saveThemeMode, [mode]),
        returnValue: Future<void>.value(),
      );

  @override
  Future<void> saveGridViewPreference(bool isGridView) => super.noSuchMethod(
        Invocation.method(#saveGridViewPreference, [isGridView]),
        returnValue: Future<void>.value(),
      );

  @override
  Future<void> saveSubtitlesEnabled(bool enabled) => super.noSuchMethod(
        Invocation.method(#saveSubtitlesEnabled, [enabled]),
        returnValue: Future<void>.value(),
      );
}

void main() {
  group('SettingsRepositoryImpl Tests', () {
    late SettingsRepositoryImpl repository;
    late MockSettingsLocalDataSource mockLocalDataSource;

    setUp(() {
      mockLocalDataSource = MockSettingsLocalDataSource();
      repository = SettingsRepositoryImpl(localDataSource: mockLocalDataSource);
    });

    group('getSettings Tests', () {
      test('should get complete settings from local data source', () async {
        // arrange
        when(mockLocalDataSource.getThemeMode())
            .thenAnswer((_) async => ThemeMode.dark);
        when(mockLocalDataSource.getGridViewPreference())
            .thenAnswer((_) async => false);
        when(mockLocalDataSource.getSubtitlesEnabled())
            .thenAnswer((_) async => true);

        // act
        final result = await repository.getSettings();

        // assert
        expect(result.themeMode, ThemeMode.dark);
        expect(result.isGridView, false);
        expect(result.subtitlesEnabled, true);
        verify(mockLocalDataSource.getThemeMode()).called(1);
        verify(mockLocalDataSource.getGridViewPreference()).called(1);
        verify(mockLocalDataSource.getSubtitlesEnabled()).called(1);
        verifyNoMoreInteractions(mockLocalDataSource);
      });

      test('should get settings with default values', () async {
        // arrange
        when(mockLocalDataSource.getThemeMode())
            .thenAnswer((_) async => ThemeMode.system);
        when(mockLocalDataSource.getGridViewPreference())
            .thenAnswer((_) async => true);
        when(mockLocalDataSource.getSubtitlesEnabled())
            .thenAnswer((_) async => true);

        // act
        final result = await repository.getSettings();

        // assert
        expect(result.themeMode, ThemeMode.system);
        expect(result.isGridView, true);
        expect(result.subtitlesEnabled, true);
        verify(mockLocalDataSource.getThemeMode()).called(1);
        verify(mockLocalDataSource.getGridViewPreference()).called(1);
        verify(mockLocalDataSource.getSubtitlesEnabled()).called(1);
      });

      test('should propagate data source exceptions', () async {
        // arrange
        final exception = Exception('Data source error');
        when(mockLocalDataSource.getThemeMode()).thenThrow(exception);

        // act & assert
        expect(() => repository.getSettings(), throwsA(exception));
        verify(mockLocalDataSource.getThemeMode()).called(1);
      });
    });

    group('saveSettings Tests', () {
      test('should save complete settings to local data source', () async {
        // arrange
        final appSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.light)
            .withGridView(false)
            .withSubtitlesEnabled(true)
            .build();

        when(mockLocalDataSource.saveThemeMode(ThemeMode.light))
            .thenAnswer((_) async {});
        when(mockLocalDataSource.saveGridViewPreference(false))
            .thenAnswer((_) async {});
        when(mockLocalDataSource.saveSubtitlesEnabled(true))
            .thenAnswer((_) async {});

        // act
        await repository.saveSettings(appSettings);

        // assert
        verify(mockLocalDataSource.saveThemeMode(ThemeMode.light)).called(1);
        verify(mockLocalDataSource.saveGridViewPreference(false)).called(1);
        verify(mockLocalDataSource.saveSubtitlesEnabled(true)).called(1);
        verifyNoMoreInteractions(mockLocalDataSource);
      });

      test('should save settings with null grid view preference', () async {
        // arrange
        final appSettings = AppSettings(
          themeMode: ThemeMode.dark,
          isGridView: null,
          subtitlesEnabled: false,
        );

        when(mockLocalDataSource.saveThemeMode(ThemeMode.dark))
            .thenAnswer((_) async {});
        when(mockLocalDataSource.saveSubtitlesEnabled(false))
            .thenAnswer((_) async {});

        // act
        await repository.saveSettings(appSettings);

        // assert
        verify(mockLocalDataSource.saveThemeMode(ThemeMode.dark)).called(1);
        verify(mockLocalDataSource.saveSubtitlesEnabled(false)).called(1);
        // saveGridViewPreference should not be called when isGridView is null
        // This is verified by verifyNoMoreInteractions below
        verifyNoMoreInteractions(mockLocalDataSource);
      });

      test('should propagate save exceptions', () async {
        // arrange
        final appSettings = AppSettingsBuilder().build();
        final exception = Exception('Save failed');
        when(mockLocalDataSource.saveThemeMode(ThemeMode.system))
            .thenThrow(exception);

        // act & assert
        expect(() => repository.saveSettings(appSettings), throwsA(exception));
        verify(mockLocalDataSource.saveThemeMode(ThemeMode.system)).called(1);
      });
    });

    group('Integration Tests', () {
      test('should handle complete settings workflow', () async {
        // arrange
        final originalSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.system)
            .withGridView(true)
            .withSubtitlesEnabled(false)
            .build();

        final updatedSettings = originalSettings.copyWith(
          themeMode: ThemeMode.dark,
          isGridView: false,
          subtitlesEnabled: true,
        );

        // Mock getting original settings
        when(mockLocalDataSource.getThemeMode())
            .thenAnswer((_) async => ThemeMode.system);
        when(mockLocalDataSource.getGridViewPreference())
            .thenAnswer((_) async => true);
        when(mockLocalDataSource.getSubtitlesEnabled())
            .thenAnswer((_) async => false);

        // Mock saving updated settings
        when(mockLocalDataSource.saveThemeMode(ThemeMode.dark))
            .thenAnswer((_) async {});
        when(mockLocalDataSource.saveGridViewPreference(false))
            .thenAnswer((_) async {});
        when(mockLocalDataSource.saveSubtitlesEnabled(true))
            .thenAnswer((_) async {});

        // act
        final retrievedSettings = await repository.getSettings();
        await repository.saveSettings(updatedSettings);

        // assert
        expect(retrievedSettings.themeMode, ThemeMode.system);
        expect(retrievedSettings.isGridView, true);
        expect(retrievedSettings.subtitlesEnabled, false);

        verify(mockLocalDataSource.saveThemeMode(ThemeMode.dark)).called(1);
        verify(mockLocalDataSource.saveGridViewPreference(false)).called(1);
        verify(mockLocalDataSource.saveSubtitlesEnabled(true)).called(1);
      });
    });
  });
}
