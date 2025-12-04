import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing audio equalizer presets
class AudioEqualizerService {
  static const String _presetsKey = 'audio_equalizer_presets';
  static const String _currentPresetKey = 'audio_equalizer_current_preset';
  static const String _gainsKey = 'audio_equalizer_gains';

  /// Default preset values (in dB)
  static final Map<String, List<double>> defaultPresets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Pop': [0.0, 0.0, 1.0, 2.0, 3.0, 2.0, 0.0, -1.0, -1.0, 0.0],
    'Rock': [4.0, 3.0, -2.0, -3.0, -2.0, 1.0, 3.0, 4.0, 4.0, 3.0],
    'Jazz': [2.0, 1.0, 0.0, 1.0, 2.0, 2.0, 1.0, 0.0, 1.0, 2.0],
    'Classical': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0],
    'Electronic': [3.0, 2.0, 0.0, 1.0, 2.0, 3.0, 2.0, 1.0, 0.0, 1.0],
    'Bass Boost': [6.0, 5.0, 3.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Treble Boost': [0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0],
  };

  /// Save a custom preset
  Future<void> savePreset(String name, List<double> gains) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPresets = await getPresets();
      existingPresets[name] = gains;
      await prefs.setString(_presetsKey, jsonEncode(existingPresets));
    } catch (e) {
      debugPrint('Error saving audio equalizer preset: $e');
    }
  }

  /// Get all saved presets (including defaults)
  Future<Map<String, List<double>>> getPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = prefs.getString(_presetsKey);
      final presets = <String, List<double>>{};
      
      // Add default presets
      presets.addAll(defaultPresets);
      
      // Add saved custom presets
      if (presetsJson != null) {
        final decoded = jsonDecode(presetsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (!defaultPresets.containsKey(entry.key)) {
            presets[entry.key] = List<double>.from(entry.value as List);
          }
        }
      }
      
      return presets;
    } catch (e) {
      debugPrint('Error loading audio equalizer presets: $e');
      return defaultPresets;
    }
  }

  /// Delete a preset (only custom ones)
  Future<void> deletePreset(String name) async {
    if (defaultPresets.containsKey(name)) {
      // Cannot delete default presets
      return;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingPresets = await getPresets();
      existingPresets.remove(name);
      
      // Remove default presets before saving
      final customPresets = <String, List<double>>{};
      for (final entry in existingPresets.entries) {
        if (!defaultPresets.containsKey(entry.key)) {
          customPresets[entry.key] = entry.value;
        }
      }
      
      await prefs.setString(_presetsKey, jsonEncode(customPresets));
    } catch (e) {
      debugPrint('Error deleting audio equalizer preset: $e');
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
      return prefs.getString(_currentPresetKey) ?? 'Flat';
    } catch (e) {
      debugPrint('Error getting current preset: $e');
      return 'Flat';
    }
  }

  /// Save current gains
  Future<void> saveGains(List<double> gains) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_gainsKey, jsonEncode(gains));
    } catch (e) {
      debugPrint('Error saving gains: $e');
    }
  }

  /// Get saved gains
  Future<List<double>?> getGains() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gainsJson = prefs.getString(_gainsKey);
      if (gainsJson != null) {
        return List<double>.from(jsonDecode(gainsJson) as List);
      }
    } catch (e) {
      debugPrint('Error getting gains: $e');
    }
    return null;
  }
}

