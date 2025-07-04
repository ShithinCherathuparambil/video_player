import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/domain/usecases/get_subtitles_enabled.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('GetSubtitlesEnabled Use Case Tests', () {
    late GetSubtitlesEnabled usecase;
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockSettingsRepository = MockFactories.createMockSettingsRepository();
      usecase = GetSubtitlesEnabled(mockSettingsRepository);
    });

    group('Successful Execution Tests', () {
      test('should return true when subtitles are enabled', () async {
        // arrange
        final settingsWithSubtitlesEnabled =
            AppSettingsBuilder().withSubtitlesEnabled(true).build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settingsWithSubtitlesEnabled);

        // act
        final result = await usecase.call();

        // assert
        expect(result, true);
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should return false when subtitles are disabled', () async {
        // arrange
        final settingsWithSubtitlesDisabled =
            AppSettingsBuilder().withSubtitlesEnabled(false).build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settingsWithSubtitlesDisabled);

        // act
        final result = await usecase.call();

        // assert
        expect(result, false);
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should return default value when settings are default', () async {
        // arrange
        final defaultSettings = AppSettingsBuilder().build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => defaultSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result, true); // Default value is true
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
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
        final settings =
            AppSettingsBuilder().withSubtitlesEnabled(true).build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);

        // act
        final futures = List.generate(5, (_) => usecase.call());
        final results = await Future.wait(futures);

        // assert
        for (final result in results) {
          expect(result, true);
        }
        verify(mockSettingsRepository.getSettings()).called(5);
      });
    });

    group('Business Logic Tests', () {
      test('should extract subtitles preference from complete settings',
          () async {
        // arrange
        final complexSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .withGridView(false)
            .withSubtitlesEnabled(true)
            .withVideoDecoder('hardware')
            .withHardwareAcceleration(false)
            .build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => complexSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result, true);
        verify(mockSettingsRepository.getSettings()).called(1);
      });

      test('should handle settings with mixed preferences', () async {
        // arrange
        final mixedSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.light)
            .withGridView(true)
            .withSubtitlesEnabled(false)
            .withVideoDecoder('software')
            .withHardwareAcceleration(true)
            .build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => mixedSettings);

        // act
        final result = await usecase.call();

        // assert
        expect(result, false);
        verify(mockSettingsRepository.getSettings()).called(1);
      });
    });

    group('Integration Tests', () {
      test('should work correctly with repository implementation', () async {
        // arrange
        final settings =
            AppSettingsBuilder().withSubtitlesEnabled(true).build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);

        // act
        final result = await usecase.call();

        // assert
        expect(result, true);
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });
    });
  });
}
