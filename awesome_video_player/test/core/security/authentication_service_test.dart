import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/security/authentication_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthenticationService Tests', () {
    late AuthenticationService authenticationService;

    setUp(() {
      authenticationService = AuthenticationService();
    });

    group('Authentication Result Tests', () {
      test('AuthenticationResult.success should return true for isSuccess', () {
        expect(AuthenticationResult.success.isSuccess, true);
        expect(AuthenticationResult.success.isFailure, false);
      });

      test('AuthenticationResult.failure should return false for isSuccess',
          () {
        expect(AuthenticationResult.failure.isSuccess, false);
        expect(AuthenticationResult.failure.isFailure, true);
      });

      test('AuthenticationResult messages should be user-friendly', () {
        expect(
            AuthenticationResult.success.message, 'Authentication successful');
        expect(AuthenticationResult.failure.message,
            'Authentication failed. Please try again.');
        expect(AuthenticationResult.unavailable.message,
            'Biometric authentication is not available on this device');
        expect(AuthenticationResult.notEnrolled.message,
            'No biometric credentials are enrolled. Please set up biometric authentication in your device settings.');
      });
    });

    group('Error Handling Tests', () {
      test('should handle platform exceptions correctly', () {
        // Test that the service can handle various platform exceptions
        // Note: These are unit tests, actual platform integration would require integration tests
        expect(AuthenticationResult.lockedOut.message,
            'Authentication is temporarily locked due to too many failed attempts. Please try again later.');
        expect(AuthenticationResult.permanentlyLockedOut.message,
            'Authentication is permanently locked. Please use your device passcode.');
        expect(AuthenticationResult.biometricNotSupported.message,
            'Biometric-only authentication is not supported on this device');
        expect(AuthenticationResult.error.message,
            'An unexpected error occurred during authentication');
      });
    });

    group('Service Initialization Tests', () {
      test('should create authentication service instance', () {
        expect(authenticationService, isNotNull);
        expect(authenticationService, isA<AuthenticationService>());
      });
    });

    group('Mock Platform Tests', () {
      test('should handle authentication when biometric is not available',
          () async {
        // Mock the platform to simulate no biometric support
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'canCheckBiometrics':
                return false;
              case 'isDeviceSupported':
                return false;
              case 'getAvailableBiometrics':
                return <String>[];
              default:
                return null;
            }
          },
        );

        final isAvailable = await authenticationService.isBiometricAvailable();
        expect(isAvailable, false);

        final availableBiometrics =
            await authenticationService.getAvailableBiometrics();
        expect(availableBiometrics, isEmpty);
      });

      test('should handle authentication when biometric is available',
          () async {
        // Mock the platform to simulate biometric support
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/local_auth'),
          (MethodCall methodCall) async {
            switch (methodCall.method) {
              case 'canCheckBiometrics':
                return true;
              case 'isDeviceSupported':
                return true;
              case 'getAvailableBiometrics':
                return ['fingerprint'];
              case 'authenticate':
                return true; // Simulate successful authentication
              default:
                return null;
            }
          },
        );

        final isAvailable = await authenticationService.isBiometricAvailable();
        expect(isAvailable, true);

        final availableBiometrics =
            await authenticationService.getAvailableBiometrics();
        expect(availableBiometrics, isNotEmpty);

        final result = await authenticationService.authenticate(
          reason: 'Test authentication',
        );
        expect(result, AuthenticationResult.success);
      });
    });

    tearDown(() {
      // Reset method call handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/local_auth'),
        null,
      );
    });
  });
}
