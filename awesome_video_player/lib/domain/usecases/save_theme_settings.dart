import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/repositories/settings_repository.dart';

class SaveThemeSettings {
  final SettingsRepository _repository;

  SaveThemeSettings(this._repository);

  /// Executes the use case to save theme-related settings.
  /// This takes the entire AppSettings object. The ThemeProvider would be responsible
  /// for constructing this AppSettings object with the new ThemeMode.
  Future<void> call(AppSettings settings) async {
    // It's assumed that the `settings` object passed here is complete
    // and valid. The ThemeProvider, for instance, would update the ThemeMode
    // within an existing AppSettings object (or create a new one) and pass it here.
    return await _repository.saveSettings(settings);
  }
}
