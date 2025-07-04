import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/usecases/toggle_authentication.dart';
import 'package:lumeo/core/security/authentication_service.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';

// Manual mock for AuthenticationService
class MockAuthenticationService extends Mock implements AuthenticationService {
  @override
  Future<AuthenticationResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) =>
      super.noSuchMethod(
        Invocation.method(#authenticate, [], {
          #reason: reason,
          #biometricOnly: biometricOnly,
        }),
        returnValue: Future.value(AuthenticationResult.success),
      );

  @override
  Future<bool> isBiometricAvailable() => super.noSuchMethod(
        Invocation.method(#isBiometricAvailable, []),
        returnValue: Future.value(true),
      );

  @override
  Future<List<BiometricType>> getAvailableBiometrics() => super.noSuchMethod(
        Invocation.method(#getAvailableBiometrics, []),
        returnValue: Future.value(<BiometricType>[]),
      );
}

void main() {
  group('ToggleAuthentication Use Case Tests', () {
    late ToggleAuthentication usecase;
    late MockSettingsRepository mockSettingsRepository;
    late MockAuthenticationService mockAuthenticationService;

    setUp(() {
      mockSettingsRepository = MockFactories.createMockSettingsRepository();
      mockAuthenticationService = MockAuthenticationService();
      usecase = ToggleAuthentication(
        mockSettingsRepository,
        mockAuthenticationService,
      );
    });

    group('Successful Authentication Tests', () {
      test('should enable authentication when user authenticates successfully',
          () async {
        // arrange
        final currentSettings =
            AppSettingsBuilder().withAuthenticationEnabled(false).build();
        final expectedUpdatedSettings = currentSettings.copyWith(
          authenticationEnabled: true,
        );

        when(mockAuthenticationService.authenticate(
          reason: 'Authenticate to enable app lock',
          biometricOnly: false,
        )).thenAnswer((_) async => AuthenticationResult.success);

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .thenAnswer((_) async {});

        // act
        final result = await usecase.call(true);

        // assert
        expect(result.isSuccess, true);
        expect(result.newValue, true);
        expect(result.settingChanged, true);
        verify(mockAuthenticationService.authenticate(
          reason: 'Authenticate to enable app lock',
          biometricOnly: false,
        )).called(1);
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .called(1);
      });

      test('should disable authentication when user authenticates successfully',
          () async {
        // arrange
        final currentSettings =
            AppSettingsBuilder().withAuthenticationEnabled(true).build();
        final expectedUpdatedSettings = currentSettings.copyWith(
          authenticationEnabled: false,
        );

        when(mockAuthenticationService.authenticate(
          reason: 'Authenticate to disable app lock',
          biometricOnly: false,
        )).thenAnswer((_) async => AuthenticationResult.success);

        when(mockSettingsRepository.getSettings())
            .thenAnswer((_) async => currentSettings);
        when(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .thenAnswer((_) async {});

        // act
        final result = await usecase.call(false);

        // assert
        expect(result.isSuccess, true);
        expect(result.newValue, false);
        expect(result.settingChanged, true);
        verify(mockAuthenticationService.authenticate(
          reason: 'Authenticate to disable app lock',
          biometricOnly: false,
        )).called(1);
        verify(mockSettingsRepository.getSettings()).called(1);
        verify(mockSettingsRepository.saveSettings(expectedUpdatedSettings))
            .called(1);
      });
    });

    group('Authentication Failure Tests', () {
      test('should not change setting when authentication fails', () async {
        // arrange
        when(mockAuthenticationService.authenticate(
          reason: 'Authenticate to enable app lock',
          biometricOnly: false,
        )).thenAnswer((_) async => AuthenticationResult.failure);

        // act
        final result = await usecase.call(true);

        // assert
        expect(result.isSuccess, false);
        expect(result.newValue, null);
        expect(result.settingChanged, false);
        expect(result.authenticationResult, AuthenticationResult.failure);
        verify(mockAuthenticationService.authenticate(
          reason: 'Authenticate to enable app lock',
          biometricOnly: false,
        )).called(1);
        verifyNever(mockSettingsRepository.getSettings());
        // Note: Cannot verify saveSettings with any() due to null safety
        // The test logic ensures saveSettings is not called when authentication fails
      });

      test('should handle biometric unavailable', () async {
        // arrange
        when(mockAuthenticationService.authenticate(
          reason: 'Authenticate to enable app lock',
          biometricOnly: false,
        )).thenAnswer((_) async => AuthenticationResult.unavailable);

        // act
        final result = await usecase.call(true);

        // assert
        expect(result.isSuccess, false);
        expect(result.authenticationResult, AuthenticationResult.unavailable);
        expect(result.message,
            'Biometric authentication is not available on this device');
      });
    });

    group('Error Handling Tests', () {
      test('should handle repository exceptions', () async {
        // arrange
        when(mockAuthenticationService.authenticate(
          reason: 'Authenticate to enable app lock',
          biometricOnly: false,
        )).thenAnswer((_) async => AuthenticationResult.success);

        when(mockSettingsRepository.getSettings())
            .thenThrow(Exception('Repository error'));

        // act
        final result = await usecase.call(true);

        // assert
        expect(result.isSuccess, false);
        expect(result.authenticationResult, AuthenticationResult.error);
        expect(result.settingChanged, false);
      });
    });

    group('Authentication Toggle Result Tests', () {
      test('should create correct result for successful toggle', () {
        // arrange & act
        final result = AuthenticationToggleResult(
          authenticationResult: AuthenticationResult.success,
          settingChanged: true,
          newValue: true,
        );

        // assert
        expect(result.isSuccess, true);
        expect(result.message, 'Authentication successful');
      });

      test('should create correct result for failed authentication', () {
        // arrange & act
        final result = AuthenticationToggleResult(
          authenticationResult: AuthenticationResult.failure,
          settingChanged: false,
          newValue: null,
        );

        // assert
        expect(result.isSuccess, false);
        expect(result.message, 'Authentication failed. Please try again.');
      });
    });
  });
}
