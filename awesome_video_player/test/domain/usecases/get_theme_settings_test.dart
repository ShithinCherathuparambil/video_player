import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/usecases/get_theme_settings.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('GetThemeSettings Use Case Tests', () {
    late GetThemeSettings usecase;
    late MockSettingsRepository mockSettingsRepository;
    late AppSettings testAppSettings;

    setUp(() {
      mockSettingsRepository = MockFactories.createMockSettingsRepository();
      usecase = GetThemeSettings(mockSettingsRepository);
      testAppSettings = AppSettingsBuilder()
          .withThemeMode(ThemeMode.dark)
          .withGridView(true)
          .withSubtitlesEnabled(false)
          .build();
    });

    group('Successful Execution Tests', () {
      test('should get app settings from repository', () async {
        // arrange
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => testAppSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result, testAppSettings);
        expect(result.themeMode, ThemeMode.dark);
        expect(result.isGridView, true);
        expect(result.subtitlesEnabled, false);
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should get light theme settings', () async {
        // arrange
        final lightSettings = AppSettingsBuilder().asLightTheme().build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => lightSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result.themeMode, ThemeMode.light);
        verify(mockSettingsRepository.getSettings()).called(1);
      });

      test('should get system theme settings', () async {
        // arrange
        final systemSettings = AppSettingsBuilder().asSystemTheme().build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => systemSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result.themeMode, ThemeMode.system);
        verify(mockSettingsRepository.getSettings()).called(1);
      });

      test('should get settings with all preferences', () async {
        // arrange
        final completeSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .withGridView(false)
            .withSubtitlesEnabled(true)
            .withVideoDecoder('hardware')
            .withHardwareAcceleration(false)
            .build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => completeSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result.themeMode, ThemeMode.dark);
        expect(result.isGridView, false);
        expect(result.subtitlesEnabled, true);
        expect(result.videoDecoder, 'hardware');
        expect(result.hardwareAcceleration, false);
        verify(mockSettingsRepository.getSettings()).called(1);
      });
    });

    group('Error Handling Tests', () {
      test('should propagate repository exceptions', () async {
        // arrange
        final exception = Exception('Settings load failed');
        when(mockSettingsRepository.getSettings()).thenThrow(exception);

        // act & assert
        expect(() => usecase.call(), throwsA(exception));
        verify(mockSettingsRepository.getSettings()).called(1);
      });

      test('should propagate storage exceptions', () async {
        // arrange
        final storageException = Exception('Storage error');
        when(mockSettingsRepository.getSettings()).thenThrow(storageException);

        // act & assert
        expect(() => usecase.call(), throwsA(storageException));
        verify(mockSettingsRepository.getSettings()).called(1);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent calls', () async {
        // arrange
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => testAppSettings);

        // act
        final futures = List.generate(5, (_) => usecase.call());
        final results = await Future.wait(futures);

        // assert
        for (final result in results) {
          expect(result, testAppSettings);
        }
        verify(mockSettingsRepository.getSettings()).called(5);
      });
    });

    group('Integration Tests', () {
      test('should work correctly with repository implementation', () async {
        // arrange
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => testAppSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result, testAppSettings);
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });
    });
  });
}
