import 'package:lumeo/core/security/authentication_service.dart';
import 'package:lumeo/domain/repositories/settings_repository.dart';

/// Use case for toggling authentication on/off
/// Requires authentication before enabling or disabling
class ToggleAuthentication {
  final SettingsRepository _settingsRepository;
  final AuthenticationService _authenticationService;

  ToggleAuthentication(
    this._settingsRepository,
    this._authenticationService,
  );

  /// Toggle authentication setting
  /// Returns the result of the authentication attempt and the new setting value
  Future<AuthenticationToggleResult> call(bool enable) async {
    try {
      // Always require authentication before changing the setting
      final authResult = await _authenticationService.authenticate(
        reason: enable
            ? 'Authenticate to enable app lock'
            : 'Authenticate to disable app lock',
        biometricOnly: false,
      );

      if (!authResult.isSuccess) {
        return AuthenticationToggleResult(
          authenticationResult: authResult,
          settingChanged: false,
          newValue: null,
        );
      }

      // Get current settings
      final currentSettings = await _settingsRepository.getSettings();

      // Update the authentication setting
      final updatedSettings = currentSettings.copyWith(
        authenticationEnabled: enable,
      );

      // Save the updated settings
      await _settingsRepository.saveSettings(updatedSettings);

      return AuthenticationToggleResult(
        authenticationResult: authResult,
        settingChanged: true,
        newValue: enable,
      );
    } catch (e) {
      return AuthenticationToggleResult(
        authenticationResult: AuthenticationResult.error,
        settingChanged: false,
        newValue: null,
      );
    }
  }
}

/// Result of authentication toggle operation
class AuthenticationToggleResult {
  final AuthenticationResult authenticationResult;
  final bool settingChanged;
  final bool? newValue;

  const AuthenticationToggleResult({
    required this.authenticationResult,
    required this.settingChanged,
    required this.newValue,
  });

  bool get isSuccess => authenticationResult.isSuccess && settingChanged;
  String get message => authenticationResult.message;
}
