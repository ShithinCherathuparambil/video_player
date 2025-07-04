import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/usecases/save_subtitles_enabled.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';

void main() {
  group('SaveSubtitlesEnabled Use Case Tests', () {
    late SaveSubtitlesEnabled usecase;
    late MockSettingsRepository mockSettingsRepository;

    setUp(() {
      mockSettingsRepository = MockFactories.createMockSettingsRepository();
      usecase = SaveSubtitlesEnabled(mockSettingsRepository);
    });

    group('Successful Execution Tests', () {
      test('should enable subtitles when passed true', () async {
        // arrange
        final currentSettings =
            AppSettingsBuilder().withSubtitlesEnabled(false).build();
        final expectedUpdatedSettings =
            currentSettings.copyWith(subtitlesEnabled: true);

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(true);

        // assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should disable subtitles when passed false', () async {
        // arrange
        final currentSettings =
            AppSettingsBuilder().withSubtitlesEnabled(true).build();
        final expectedUpdatedSettings =
            currentSettings.copyWith(subtitlesEnabled: false);

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(false);

        // assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should preserve other settings when updating subtitles', () async {
        // arrange
        final currentSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.dark)
            .withGridView(false)
            .withSubtitlesEnabled(false)
            .withVideoDecoder('hardware')
            .withHardwareAcceleration(true)
            .build();
        final expectedUpdatedSettings =
            currentSettings.copyWith(subtitlesEnabled: true);

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .thenAnswer((_) async {});

        // act
        await usecase.call(true);

        // assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });

      test('should handle toggling subtitles multiple times', () async {
        // arrange
        final initialSettings =
            AppSettingsBuilder().withSubtitlesEnabled(false).build();

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => initialSettings);
        when(mockSettingsRepository.saveSettings(isA<AppSettings>()))
            .thenAnswer((_) async {});

        // act - toggle multiple times
        await usecase.call(true);
        await usecase.call(false);
        await usecase.call(true);

        // assert
        verify(mockSettingsRepository.getSettings()).called(3);
        verify(mockSettingsRepository.saveSettings(argThat(isA<AppSettings>())))
            .called(3);
      });
    });

    group('Error Handling Tests', () {
      test('should propagate get settings exceptions', () async {
        // arrange
        final exception = Exception('Failed to get settings');
        when(mockSettingsRepository.getSettings()).thenThrow(exception);

        // act & assert
        expect(() => usecase.call(true), throwsA(exception));
        verify(mockSettingsRepository.getSettings()).called(1);
        verifyNever(
            mockSettingsRepository.saveSettings(argThat(isA<AppSettings>())));
      });

      test('should propagate save settings exceptions', () async {
        // arrange
        final currentSettings = AppSettingsBuilder().build();
        final saveException = Exception('Failed to save settings');

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(any)).thenThrow(saveException);

        // act & assert
        expect(() => usecase.call(true), throwsA(saveException));
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(any)).called(1);
      });

      test('should propagate storage exceptions', () async {
        // arrange
        final currentSettings = AppSettingsBuilder().build();
        final storageException = Exception('Storage error');

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(any))
            .thenThrow(storageException);

        // act & assert
        expect(() => usecase.call(false), throwsA(storageException));
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(any)).called(1);
      });
    });

    group('Data Integrity Tests', () {
      test('should maintain all other settings properties', () async {
        // arrange
        final originalSettings = AppSettingsBuilder()
            .withThemeMode(ThemeMode.system)
            .withGridView(true)
            .withSubtitlesEnabled(false)
            .withVideoDecoder('auto')
            .withHardwareAcceleration(false)
            .build();

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => originalSettings);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act
        await usecase.call(true);

        // assert
        final captured = verify(mockSettingsRepository.saveSettings(captureAny))
            .captured
            .single as AppSettings;

        expect(captured.themeMode, ThemeMode.system);
        expect(captured.isGridView, true);
        expect(captured.subtitlesEnabled, true); // This should be updated
        expect(captured.videoDecoder, 'auto');
        expect(captured.hardwareAcceleration, false);
      });

      test('should handle null grid view preference correctly', () async {
        // arrange
        final settingsWithNullGridView = AppSettings(
          themeMode: ThemeMode.light,
          isGridView: null,
          subtitlesEnabled: false,
        );

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settingsWithNullGridView);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act
        await usecase.call(true);

        // assert
        final captured = verify(mockSettingsRepository.saveSettings(captureAny))
            .captured
            .single as AppSettings;

        expect(captured.themeMode, ThemeMode.light);
        expect(captured.isGridView, null);
        expect(captured.subtitlesEnabled, true);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent calls', () async {
        // arrange
        final settings = AppSettingsBuilder().build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act
        final futures = [
          usecase.call(true),
          usecase.call(false),
          usecase.call(true),
        ];
        await Future.wait(futures);

        // assert
        verify(mockSettingsRepository.getSettings()).called(3);
        verify(mockSettingsRepository.saveSettings(any)).called(3);
      });

      test('should handle rapid successive calls', () async {
        // arrange
        final settings = AppSettingsBuilder().build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act - simulate rapid toggling
        for (int i = 0; i < 5; i++) {
          await usecase.call(i % 2 == 0);
        }

        // assert
        verify(mockSettingsRepository.getSettings()).called(5);
        verify(mockSettingsRepository.saveSettings(any)).called(5);
      });
    });

    group('Business Logic Tests', () {
      test('should correctly update subtitles preference', () async {
        // arrange
        final disabledSettings =
            AppSettingsBuilder().withSubtitlesEnabled(false).build();

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => disabledSettings);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act
        await usecase.call(true);

        // assert
        final captured = verify(mockSettingsRepository.saveSettings(captureAny))
            .captured
            .single as AppSettings;
        expect(captured.subtitlesEnabled, true);
      });

      test('should handle idempotent operations', () async {
        // arrange
        final enabledSettings =
            AppSettingsBuilder().withSubtitlesEnabled(true).build();

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => enabledSettings);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act - enable when already enabled
        await usecase.call(true);

        // assert
        final captured = verify(mockSettingsRepository.saveSettings(captureAny))
            .captured
            .single as AppSettings;
        expect(captured.subtitlesEnabled, true);
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(any)).called(1);
      });
    });

    group('Integration Tests', () {
      test('should work correctly with repository implementation', () async {
        // arrange
        final settings =
            AppSettingsBuilder().withSubtitlesEnabled(false).build();
        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => settings);
        when(mockSettingsRepository.saveSettings(any)).thenAnswer((_) async {});

        // act
        await usecase.call(true);

        // assert
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(any)).called(1);
        verifyNoMoreInteractions(mockSettingsRepository);
      });
    });
  });
}
