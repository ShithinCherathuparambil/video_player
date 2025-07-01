import 'package:lumeo/domain/entities/app_settings.dart';

abstract class SettingsRepository {
  /// Retrieves the current application settings.
  ///
  /// Returns default settings if no settings are persisted.
  Future<AppSettings> getSettings();

  /// Saves the application settings.
  ///
  /// Throws an exception if saving fails.
  Future<void> saveSettings(AppSettings settings);
}
