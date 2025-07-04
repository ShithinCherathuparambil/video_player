import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Service for handling biometric and PIN authentication
class AuthenticationService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate user using biometric or PIN
  /// Returns true if authentication is successful, false otherwise
  Future<AuthenticationResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      // Check if biometric authentication is available
      final bool isAvailable = await isBiometricAvailable();

      if (!isAvailable && biometricOnly) {
        return AuthenticationResult.unavailable;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      return didAuthenticate
          ? AuthenticationResult.success
          : AuthenticationResult.failure;
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      return AuthenticationResult.error;
    }
  }

  /// Handle platform-specific authentication exceptions
  AuthenticationResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return AuthenticationResult.unavailable;
      case auth_error.notEnrolled:
        return AuthenticationResult.notEnrolled;
      case auth_error.lockedOut:
        return AuthenticationResult.lockedOut;
      case auth_error.permanentlyLockedOut:
        return AuthenticationResult.permanentlyLockedOut;
      case auth_error.biometricOnlyNotSupported:
        return AuthenticationResult.biometricNotSupported;
      default:
        return AuthenticationResult.error;
    }
  }

  /// Stop authentication process
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (e) {
      return false;
    }
  }
}

/// Enum representing different authentication results
enum AuthenticationResult {
  /// Authentication was successful
  success,

  /// Authentication failed (user cancelled or wrong credentials)
  failure,

  /// Biometric authentication is not available on this device
  unavailable,

  /// User has not enrolled any biometric credentials
  notEnrolled,

  /// Authentication is temporarily locked due to too many failed attempts
  lockedOut,

  /// Authentication is permanently locked due to too many failed attempts
  permanentlyLockedOut,

  /// Biometric-only authentication is not supported
  biometricNotSupported,

  /// An unexpected error occurred
  error,
}

/// Extension to provide user-friendly messages for authentication results
extension AuthenticationResultExtension on AuthenticationResult {
  String get message {
    switch (this) {
      case AuthenticationResult.success:
        return 'Authentication successful';
      case AuthenticationResult.failure:
        return 'Authentication failed. Please try again.';
      case AuthenticationResult.unavailable:
        return 'Biometric authentication is not available on this device';
      case AuthenticationResult.notEnrolled:
        return 'No biometric credentials are enrolled. Please set up biometric authentication in your device settings.';
      case AuthenticationResult.lockedOut:
        return 'Authentication is temporarily locked due to too many failed attempts. Please try again later.';
      case AuthenticationResult.permanentlyLockedOut:
        return 'Authentication is permanently locked. Please use your device passcode.';
      case AuthenticationResult.biometricNotSupported:
        return 'Biometric-only authentication is not supported on this device';
      case AuthenticationResult.error:
        return 'An unexpected error occurred during authentication';
    }
  }

  bool get isSuccess => this == AuthenticationResult.success;
  bool get isFailure => !isSuccess;
}
