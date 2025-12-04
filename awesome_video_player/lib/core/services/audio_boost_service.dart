import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing audio boost settings
class AudioBoostService {
  static const String _boostKey = 'audio_boost_level';
  static const double _maxBoost = 2.0; // 200%
  static const double _minBoost = 0.0; // 0%
  static const double _defaultBoost = 1.0; // 100%

  /// Save audio boost level (0.0 to 2.0, where 1.0 = 100%)
  Future<void> saveBoost(double boost) async {
    try {
      final clampedBoost = boost.clamp(_minBoost, _maxBoost);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_boostKey, clampedBoost);
    } catch (e) {
      debugPrint('Error saving audio boost: $e');
    }
  }

  /// Get saved audio boost level
  Future<double> getBoost() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble(_boostKey) ?? _defaultBoost;
    } catch (e) {
      debugPrint('Error getting audio boost: $e');
      return _defaultBoost;
    }
  }

  /// Apply audio boost to volume
  /// Note: Actual implementation would require platform channels or audio processing
  double applyBoost(double volume) {
    final boost = _defaultBoost; // Would get from saved preferences
    return (volume * boost).clamp(0.0, 1.0);
  }

  /// Get max boost value
  double get maxBoost => _maxBoost;

  /// Get min boost value
  double get minBoost => _minBoost;
}

