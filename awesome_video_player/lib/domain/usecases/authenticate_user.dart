import 'package:local_auth/local_auth.dart';
import 'package:lumeo/core/security/authentication_service.dart';

/// Use case for authenticating user when app starts or resumes
class AuthenticateUser {
  final AuthenticationService _authenticationService;

  AuthenticateUser(this._authenticationService);

  /// Authenticate user with biometric or PIN
  Future<AuthenticationResult> call({
    String reason = 'Authenticate to access the app',
    bool biometricOnly = false,
  }) async {
    try {
      return await _authenticationService.authenticate(reason: reason);
    } catch (e) {
      return AuthenticationResult.error;
    }
  }

  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    return await _authenticationService.isBiometricAvailable();
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _authenticationService.getAvailableBiometrics();
  }
}
