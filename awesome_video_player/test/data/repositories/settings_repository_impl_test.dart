import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart'; // For ThemeMode
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/data/datasources/settings_local_data_source.dart';
import 'package:awesome_video_player/data/repositories/settings_repository_impl.dart';

// Manual mock for SettingsLocalDataSource
class MockSettingsLocalDataSource extends Mock implements SettingsLocalDataSource {}

void main() {
  late SettingsRepositoryImpl repository;
  late MockSettingsLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getSettings', () {
    test(
      'should get ThemeMode from local data source and map to AppSettings',
      () async {
        // arrange
        when(mockLocalDataSource.getThemeMode())
            .thenAnswer((_) async => ThemeMode.dark);
        // act
        final result = await repository.getSettings();
        // assert
        expect(result, AppSettings(themeMode: ThemeMode.dark));
        verify(mockLocalDataSource.getThemeMode());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });

  group('saveSettings', () {
    test(
      'should call saveThemeMode on local data source with ThemeMode from AppSettings',
      () async {
        // arrange
        final appSettingsToSave = AppSettings(themeMode: ThemeMode.light);
        when(mockLocalDataSource.saveThemeMode(any)) // any captures ThemeMode.light
            .thenAnswer((_) async {}); // Complete successfully
        // act
        await repository.saveSettings(appSettingsToSave);
        // assert
        verify(mockLocalDataSource.saveThemeMode(appSettingsToSave.themeMode));
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });
}
