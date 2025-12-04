import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing orientation lock
class OrientationLockService {
  static const String _orientationLockKey = 'orientation_lock_per_video';
  static const String _globalOrientationLockKey = 'global_orientation_lock';

  /// Lock orientation for a specific video
  Future<void> lockOrientationForVideo(String videoPath, DeviceOrientation orientation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locks = await getVideoOrientationLocks();
      locks[videoPath] = orientation.toString();
      await prefs.setString(_orientationLockKey, jsonEncode(locks));
    } catch (e) {
      debugPrint('Error locking orientation for video: $e');
    }
  }

  /// Get orientation lock for a video
  Future<DeviceOrientation?> getOrientationForVideo(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locksJson = prefs.getString(_orientationLockKey);
      if (locksJson != null) {
        final locks = jsonDecode(locksJson) as Map<String, dynamic>;
        final orientationStr = locks[videoPath] as String?;
        if (orientationStr != null) {
          return _parseOrientation(orientationStr);
        }
      }
    } catch (e) {
      debugPrint('Error getting orientation for video: $e');
    }
    return null;
  }

  /// Get all video orientation locks
  Future<Map<String, String>> getVideoOrientationLocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locksJson = prefs.getString(_orientationLockKey);
      if (locksJson != null) {
        return Map<String, String>.from(jsonDecode(locksJson) as Map);
      }
    } catch (e) {
      debugPrint('Error getting video orientation locks: $e');
    }
    return {};
  }

  /// Set global orientation lock
  Future<void> setGlobalOrientationLock(DeviceOrientation? orientation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (orientation != null) {
        await prefs.setString(_globalOrientationLockKey, orientation.toString());
      } else {
        await prefs.remove(_globalOrientationLockKey);
      }
    } catch (e) {
      debugPrint('Error setting global orientation lock: $e');
    }
  }

  /// Get global orientation lock
  Future<DeviceOrientation?> getGlobalOrientationLock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orientationStr = prefs.getString(_globalOrientationLockKey);
      if (orientationStr != null) {
        return _parseOrientation(orientationStr);
      }
    } catch (e) {
      debugPrint('Error getting global orientation lock: $e');
    }
    return null;
  }

  /// Apply orientation lock
  Future<void> applyOrientation(DeviceOrientation? orientation) async {
    if (orientation != null) {
      await SystemChrome.setPreferredOrientations([orientation]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  DeviceOrientation? _parseOrientation(String orientationStr) {
    switch (orientationStr) {
      case 'DeviceOrientation.portraitUp':
        return DeviceOrientation.portraitUp;
      case 'DeviceOrientation.portraitDown':
        return DeviceOrientation.portraitDown;
      case 'DeviceOrientation.landscapeLeft':
        return DeviceOrientation.landscapeLeft;
      case 'DeviceOrientation.landscapeRight':
        return DeviceOrientation.landscapeRight;
      default:
        return null;
    }
  }
}

