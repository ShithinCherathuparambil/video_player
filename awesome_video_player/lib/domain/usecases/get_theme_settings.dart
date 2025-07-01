import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/repositories/settings_repository.dart';

class GetThemeSettings {
  final SettingsRepository _repository;

  GetThemeSettings(this._repository);

  /// Executes the use case to retrieve theme-related settings.
  /// Currently, this fetches all AppSettings, which includes ThemeMode.
  /// If AppSettings grows, this might be refined to fetch only theme-specific parts
  /// or ThemeProvider might directly use this and extract ThemeMode.
  Future<AppSettings> call() async {
    // For now, AppSettings primarily contains theme-related info (ThemeMode).
    // If AppSettings expands significantly, consider if a more specific
    // return type or filtering is needed here or in the calling provider.
    return await _repository.getSettings();
  }
}
