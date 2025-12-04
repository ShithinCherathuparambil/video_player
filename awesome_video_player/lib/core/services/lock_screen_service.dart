import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing lock screen state
class LockScreenService {
  static const String _lockStateKey = 'lock_screen_state';
  static const String _kidsLockEnabledKey = 'kids_lock_enabled';
  static const String _kidsLockPinKey = 'kids_lock_pin';

  /// Save lock screen state
  Future<void> saveLockState(bool isLocked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lockStateKey, isLocked);
    } catch (e) {
      debugPrint('Error saving lock state: $e');
    }
  }

  /// Get lock screen state
  Future<bool> getLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_lockStateKey) ?? false;
    } catch (e) {
      debugPrint('Error getting lock state: $e');
      return false;
    }
  }

  /// Enable/disable kids lock
  Future<void> setKidsLockEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kidsLockEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error setting kids lock: $e');
    }
  }

  /// Check if kids lock is enabled
  Future<bool> isKidsLockEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kidsLockEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error getting kids lock state: $e');
      return false;
    }
  }

  /// Set kids lock PIN
  Future<void> setKidsLockPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kidsLockPinKey, pin);
    } catch (e) {
      debugPrint('Error setting kids lock PIN: $e');
    }
  }

  /// Verify kids lock PIN
  Future<bool> verifyKidsLockPin(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString(_kidsLockPinKey);
      return savedPin == pin;
    } catch (e) {
      debugPrint('Error verifying kids lock PIN: $e');
      return false;
    }
  }
}

