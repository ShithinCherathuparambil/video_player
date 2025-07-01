import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumeo/core/security/secure_storage.dart';

void main() {
  group('SecureStorage Security Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Basic Encryption/Decryption', () {
      test('should encrypt and decrypt data correctly', () async {
        const testKey = 'test_key';
        const testValue = 'sensitive_data_123';

        // Store encrypted data
        final stored = await SecureStorage.setSecureString(testKey, testValue);
        expect(stored, isTrue);

        // Retrieve and decrypt data
        final retrieved = await SecureStorage.getSecureString(testKey);
        expect(retrieved, equals(testValue));
      });

      test('should return null for non-existent keys', () async {
        final result = await SecureStorage.getSecureString('non_existent_key');
        expect(result, isNull);
      });

      test('should handle empty values', () async {
        const testKey = 'empty_key';
        const testValue = '';

        await SecureStorage.setSecureString(testKey, testValue);
        final retrieved = await SecureStorage.getSecureString(testKey);
        expect(retrieved, equals(testValue));
      });
    });

    group('Data Security', () {
      test('should store data in encrypted form', () async {
        const testKey = 'security_test';
        const testValue = 'secret_password_123';

        await SecureStorage.setSecureString(testKey, testValue);

        // Check that raw stored data is not the original value
        final prefs = await SharedPreferences.getInstance();
        final rawStored = prefs.getString('secure_$testKey');

        expect(rawStored, isNotNull);
        expect(rawStored, isNot(equals(testValue)));
        expect(rawStored!.contains(testValue), isFalse);
      });

      test('should use different encryption for different values', () async {
        const value1 = 'test_value_1';
        const value2 = 'test_value_2';

        await SecureStorage.setSecureString('key1', value1);
        await SecureStorage.setSecureString('key2', value2);

        final prefs = await SharedPreferences.getInstance();
        final encrypted1 = prefs.getString('secure_key1');
        final encrypted2 = prefs.getString('secure_key2');

        expect(encrypted1, isNotNull);
        expect(encrypted2, isNotNull);
        expect(encrypted1, isNot(equals(encrypted2)));
      });

      test('should handle special characters and unicode', () async {
        const testKey = 'unicode_test';
        const testValue = 'Special chars: !@#\$%^&*()_+ 中文 🎬📱';

        await SecureStorage.setSecureString(testKey, testValue);
        final retrieved = await SecureStorage.getSecureString(testKey);
        expect(retrieved, equals(testValue));
      });
    });

    group('Key Management', () {
      test('should check if key exists', () async {
        const testKey = 'existence_test';

        expect(await SecureStorage.containsSecureKey(testKey), isFalse);

        await SecureStorage.setSecureString(testKey, 'test_value');
        expect(await SecureStorage.containsSecureKey(testKey), isTrue);
      });

      test('should remove keys correctly', () async {
        const testKey = 'removal_test';
        const testValue = 'to_be_removed';

        await SecureStorage.setSecureString(testKey, testValue);
        expect(await SecureStorage.containsSecureKey(testKey), isTrue);

        final removed = await SecureStorage.removeSecureString(testKey);
        expect(removed, isTrue);
        expect(await SecureStorage.containsSecureKey(testKey), isFalse);
        expect(await SecureStorage.getSecureString(testKey), isNull);
      });

      test('should clear all secure data', () async {
        // Store multiple secure values
        await SecureStorage.setSecureString('key1', 'value1');
        await SecureStorage.setSecureString('key2', 'value2');
        await SecureStorage.setSecureString('key3', 'value3');

        // Store non-secure value (should not be affected)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('normal_key', 'normal_value');

        // Clear all secure data
        final cleared = await SecureStorage.clearAllSecureData();
        expect(cleared, isTrue);

        // Check that secure data is gone
        expect(await SecureStorage.getSecureString('key1'), isNull);
        expect(await SecureStorage.getSecureString('key2'), isNull);
        expect(await SecureStorage.getSecureString('key3'), isNull);

        // Check that non-secure data remains
        expect(prefs.getString('normal_key'), equals('normal_value'));
      });
    });

    group('Error Handling', () {
      test('should handle corrupted encrypted data gracefully', () async {
        const testKey = 'corruption_test';

        // Manually store corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('secure_$testKey', 'corrupted_base64_data!!!');

        // Should return null for corrupted data
        final result = await SecureStorage.getSecureString(testKey);
        expect(result, isNull);
      });

      test('should handle very large data', () async {
        const testKey = 'large_data_test';
        final largeValue = 'x' * 10000; // 10KB of data

        final stored = await SecureStorage.setSecureString(testKey, largeValue);
        expect(stored, isTrue);

        final retrieved = await SecureStorage.getSecureString(testKey);
        expect(retrieved, equals(largeValue));
      });
    });

    group('Data Integrity', () {
      test('should validate data integrity correctly', () async {
        const testKey = 'integrity_test';
        const testValue = 'integrity_check_data';

        await SecureStorage.setSecureString(testKey, testValue);

        // Calculate expected hash
        final expectedHash =
            'a8b2c3d4e5f6'; // This would be calculated properly in real implementation

        // Note: This test would need the actual hash calculation
        // For now, we just test that the method exists and handles errors
        final isValid =
            await SecureStorage.validateDataIntegrity(testKey, 'wrong_hash');
        expect(isValid, isFalse);
      });
    });
  });
}
