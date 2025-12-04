import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing video effects presets
class VideoEffectsService {
  static const String _presetsKey = 'video_effects_presets';
  static const String _currentPresetKey = 'video_effects_current_preset';

  /// Save a custom preset
  Future<void> savePreset(String name, Map<String, double> values) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPresets = await getPresets();
      existingPresets[name] = values;
      await prefs.setString(_presetsKey, jsonEncode(existingPresets));
    } catch (e) {
      debugPrint('Error saving video effects preset: $e');
    }
  }

  /// Get all saved presets
  Future<Map<String, Map<String, double>>> getPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_presetsKey);
      if (presetsJson != null) {
        final decoded = jsonDecode(presetsJson) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(
              key,
              Map<String, double>.from(value as Map),
            ));
      }
    } catch (e) {
      debugPrint('Error loading video effects presets: $e');
    }
    return {};
  }

  /// Delete a preset
  Future<void> deletePreset(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPresets = await getPresets();
      existingPresets.remove(name);
      await prefs.setString(_presetsKey, jsonEncode(existingPresets));
    } catch (e) {
      debugPrint('Error deleting video effects preset: $e');
    }
  }

  /// Save current preset name
  Future<void> saveCurrentPreset(String presetName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentPresetKey, presetName);
    } catch (e) {
      debugPrint('Error saving current preset: $e');
    }
  }

  /// Get current preset name
  Future<String?> getCurrentPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentPresetKey);
    } catch (e) {
      debugPrint('Error getting current preset: $e');
      return null;
    }
  }
}

