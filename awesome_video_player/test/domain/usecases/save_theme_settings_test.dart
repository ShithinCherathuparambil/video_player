import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/usecases/save_theme_settings.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('SaveThemeSettings Use Case Tests', () {
    late SaveThemeSettings usecase;
    late MockSettingsRepository mockSettingsRepository;
    late AppSettings testAppSettings;

    setUp(() {
      mockSettingsRepository = MockFactories.createMockSettingsRepository();
      usecase = SaveThemeSettings(mockSettingsRepository);
      testAppSettings = AppSettingsBuilder()
          .withThemeMode(ThemeMode.dark)
          .withGridView(true)
          .withSubtitlesEnabled(false)
          .build();
    });

    group('Successful Execution Tests', () {
      test('should save app settings through repository', () async {
        // arrange
        when(mockSettingsRepository.saveSettings(testAppSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(testAppSettings);

        // assert
        verify(mockSettingsRepository.saveSettings(testAppSettings)).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should save light theme settings', () async {
        // arrange
        final lightSettings = AppSettingsBuilder().asLightTheme().build();
        when(mockSettingsRepository.saveSettings(lightSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(lightSettings);

        // assert
        verify(mockSettingsRepository.saveSettings(lightSettings)).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should save dark theme settings', () async {
        // arrange
        final darkSettings = AppSettingsBuilder().asDarkTheme().build();
        when(mockSettingsRepository.saveSettings(darkSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(darkSettings);

        // assert
        verify(mockSettingsRepository.saveSettings(darkSettings)).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should save system theme settings', () async {
        // arrange
        final systemSettings = AppSettingsBuilder().asSystemTheme().build();
        when(mockSettingsRepository.saveSettings(systemSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(systemSettings);

        // assert
        verify(mockSettingsRepository.saveSettings(systemSettings)).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should save complete settings with all preferences', () async {
        // arrange
        final completeSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .withGridView(false)
            .withSubtitlesEnabled(true)
            .withVideoDecoder('hardware')
            .withHardwareAcceleration(false)
            .build();
        when(mockSettingsRepository.saveSettings(completeSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(completeSettings);

        // assert
        verify(mockSettingsRepository.saveSettings(completeSettings)).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });
    });

    group('Error Handling Tests', () {
      test('should propagate repository exceptions', () async {
        // arrange
        final exception = Exception('Save failed');
        when(mockSettingsRepository.saveSettings(testAppSettings))
            .thenThrow(exception);

        // act & assert
        expect(() => usecase.call(testAppSettings), throwsA(exception));
        verify(mockSettingsRepository.saveSettings(testAppSettings)).called(1);
      });

      test('should propagate storage exceptions', () async {
        // arrange
        final storageException = Exception('Storage full');
        when(mockSettingsRepository.saveSettings(testAppSettings))
            .thenThrow(storageException);

        // act & assert
        expect(() => usecase.call(testAppSettings), throwsA(storageException));
        verify(mockSettingsRepository.saveSettings(testAppSettings)).called(1);
      });
    });
  });
}
