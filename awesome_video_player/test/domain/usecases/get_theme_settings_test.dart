import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/repositories/settings_repository.dart';
import 'package:awesome_video_player/domain/usecases/get_theme_settings.dart';
import 'package:flutter/material.dart'; // For ThemeMode

// Generate mocks for SettingsRepository by running build_runner
// If not using build_runner, create manual mocks or use a simpler mocking approach.
// For this exercise, we'll assume manual mock or simple mock setup.
// To use @GenerateMocks, you'd add build_runner and mockito_generator to dev_dependencies
// and run `flutter pub run build_runner build`.
// Let's create a manual mock for simplicity here.

class MockSettingsRepository extends Mock implements SettingsRepository {}

@GenerateMocks([SettingsRepository]) // If using build_runner
void main() {
  late GetThemeSettings usecase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    usecase = GetThemeSettings(mockSettingsRepository);
  });

  final tAppSettings = AppSettings(themeMode: ThemeMode.dark);

  test(
    'should get app settings (including theme) from the repository',
    () async {
      // arrange
      when(mockSettingsRepository.getSettings())
          .thenAnswer((_) async => tAppSettings);
      // act
      final result = await usecase.call();
      // assert
      expect(result, tAppSettings);
      verify(mockSettingsRepository.getSettings());
      verifyNoMoreInteractions(mockSettingsRepository);
    },
  );
}
