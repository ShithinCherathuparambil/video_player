import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/repositories/settings_repository.dart';
import 'package:awesome_video_player/domain/usecases/save_theme_settings.dart';
import 'package:flutter/material.dart'; // For ThemeMode

// Re-using the manual mock from get_theme_settings_test.dart
// In a real project with build_runner, this would be generated.
class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SaveThemeSettings usecase;
  late MockSettingsRepository mockSettingsRepository;

  setUp(() {
    mockSettingsRepository = MockSettingsRepository();
    usecase = SaveThemeSettings(mockSettingsRepository);
  });

  final tAppSettings = AppSettings(themeMode: ThemeMode.light);

  test(
    'should call saveSettings on the repository with correct AppSettings',
    () async {
      // arrange
      // No specific arrangement needed for save, just verify the call.
      // Mock the saveSettings method to complete successfully.
      when(mockSettingsRepository.saveSettings(any))
          .thenAnswer((_) async => Future.value()); // Or Future.value(null) pre Dart 2.12

      // act
      await usecase.call(tAppSettings);

      // assert
      verify(mockSettingsRepository.saveSettings(tAppSettings));
      verifyNoMoreInteractions(mockSettingsRepository);
    },
  );
}
