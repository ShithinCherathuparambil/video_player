import 'package:awesome_video_player/domain/repositories/settings_repository.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';

class SaveSubtitlesEnabled {
  final SettingsRepository repository;

  SaveSubtitlesEnabled(this.repository);

  /// Executes the use case to save subtitle preferences.
  Future<void> call(bool enabled) async {
    final currentSettings = await repository.getSettings();
    final updatedSettings = currentSettings.copyWith(subtitlesEnabled: enabled);
    await repository.saveSettings(updatedSettings);
  }
}
