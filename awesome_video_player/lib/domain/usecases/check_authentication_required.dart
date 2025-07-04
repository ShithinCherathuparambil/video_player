import 'package:lumeo/domain/repositories/settings_repository.dart';

/// Use case for checking if authentication is required
class CheckAuthenticationRequired {
  final SettingsRepository _settingsRepository;

  CheckAuthenticationRequired(this._settingsRepository);

  /// Check if authentication is enabled in settings
  Future<bool> call() async {
    try {
      final settings = await _settingsRepository.getSettings();
      return settings.authenticationEnabled;
    } catch (e) {
      // If there's an error reading settings, default to false (no authentication required)
      return false;
    }
  }
}
