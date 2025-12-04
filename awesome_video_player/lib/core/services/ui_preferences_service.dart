import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing UI preferences (gestures, playback speed, etc.)
class UIPreferencesService {
  static const String _prefsKey = 'ui_preferences';

  /// Save all UI preferences
  Future<void> savePreferences({
    required bool autoLoadSubtitles,
    required bool rememberPosition,
    required bool autoPlayNext,
    required double defaultPlaybackSpeed,
    required bool volumeGesture,
    required bool brightnessGesture,
    required bool seekGesture,
    required bool doubleTapSkip,
    required bool hardwareAcceleration,
    required bool networkCaching,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferences = {
        'autoLoadSubtitles': autoLoadSubtitles,
        'rememberPosition': rememberPosition,
        'autoPlayNext': autoPlayNext,
        'defaultPlaybackSpeed': defaultPlaybackSpeed,
        'volumeGesture': volumeGesture,
        'brightnessGesture': brightnessGesture,
        'seekGesture': seekGesture,
        'doubleTapSkip': doubleTapSkip,
        'hardwareAcceleration': hardwareAcceleration,
        'networkCaching': networkCaching,
      };
      await prefs.setString(_prefsKey, jsonEncode(preferences));
    } catch (e) {
      debugPrint('Error saving UI preferences: $e');
    }
  }

  /// Load all UI preferences
  Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);
      if (prefsJson != null) {
        return jsonDecode(prefsJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading UI preferences: $e');
    }

    // Return defaults
    return {
      'autoLoadSubtitles': true,
      'rememberPosition': true,
      'autoPlayNext': true,
      'defaultPlaybackSpeed': 1.0,
      'volumeGesture': true,
      'brightnessGesture': true,
      'seekGesture': true,
      'doubleTapSkip': true,
      'hardwareAcceleration': true,
      'networkCaching': true,
    };
  }

  /// Save a single preference
  Future<void> savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPrefs = await loadPreferences();
      currentPrefs[key] = value;
      await prefs.setString(_prefsKey, jsonEncode(currentPrefs));
    } catch (e) {
      debugPrint('Error saving preference $key: $e');
    }
  }
}

