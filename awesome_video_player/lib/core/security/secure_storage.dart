import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage utility for encrypting sensitive data
class SecureStorage {
  static const String _keyPrefix = 'secure_';
  static const String _saltKey = 'app_salt';

  /// Generates a secure salt for encryption
  static Future<String> _getSalt() async {
    final prefs = await SharedPreferences.getInstance();
    String? salt = prefs.getString(_saltKey);

    if (salt == null) {
      // Generate new salt
      final random = Random.secure();
      final bytes = List<int>.generate(32, (i) => random.nextInt(256));
      salt = base64Encode(bytes);
      await prefs.setString(_saltKey, salt);
    }

    return salt;
  }

  /// Simple XOR encryption for basic data protection
  /// Note: For production apps, consider using more robust encryption
  static String _encrypt(String data, String key) {
    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64Encode(encrypted);
  }

  /// Simple XOR decryption
  static String? _decrypt(String encryptedData, String key) {
    try {
      final encryptedBytes = base64Decode(encryptedData);
      final keyBytes = utf8.encode(key);
      final decrypted = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decrypted);
    } catch (e) {
      return null;
    }
  }

  /// Generates encryption key from salt
  static Future<String> _getEncryptionKey() async {
    final salt = await _getSalt();
    final bytes = utf8.encode('awesome_video_player_$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Securely stores encrypted data
  static Future<bool> setSecureString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptionKey = await _getEncryptionKey();
      final encryptedValue = _encrypt(value, encryptionKey);
      return await prefs.setString('$_keyPrefix$key', encryptedValue);
    } catch (e) {
      return false;
    }
  }

  /// Retrieves and decrypts stored data
  static Future<String?> getSecureString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encryptedValue = prefs.getString('$_keyPrefix$key');

      if (encryptedValue == null) return null;

      final encryptionKey = await _getEncryptionKey();
      final decryptedValue = _decrypt(encryptedValue, encryptionKey);

      return decryptedValue;
    } catch (e) {
      return null;
    }
  }

  /// Removes secure data
  static Future<bool> removeSecureString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove('$_keyPrefix$key');
    } catch (e) {
      return false;
    }
  }

  /// Checks if secure key exists
  static Future<bool> containsSecureKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_keyPrefix$key');
    } catch (e) {
      return false;
    }
  }

  /// Clears all secure data
  static Future<bool> clearAllSecureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validates data integrity
  static Future<bool> validateDataIntegrity(
      String key, String expectedHash) async {
    try {
      final data = await getSecureString(key);
      if (data == null) return false;

      final dataBytes = utf8.encode(data);
      final actualHash = sha256.convert(dataBytes).toString();

      return actualHash == expectedHash;
    } catch (e) {
      return false;
    }
  }
}
