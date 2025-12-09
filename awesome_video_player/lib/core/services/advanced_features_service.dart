import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing advanced player features preferences
class AdvancedFeaturesService {
  static const String _prefsKey = 'advanced_features_preferences';

  /// Save all advanced features preferences
  Future<void> savePreferences({
    required bool hardwareAcceleration,
    required bool deinterlace,
    required bool frameDrop,
    required bool networkCaching,
    required int networkCacheSize,
    required bool audioSync,
    required double audioDelay,
    required double subtitleDelay,
    required bool showTimeRemaining,
    required bool showBuffering,
    required bool showQuality,
    required bool rememberPosition,
    required bool autoPlayNext,
    required bool shuffleEnabled,
    int? autoHideControlsDelay,
    String? selectedQuality,
    String? selectedAudioTrack,
    String? selectedSubtitleTrack,
    String? selectedVideoTrack,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferences = {
        'hardwareAcceleration': hardwareAcceleration,
        'deinterlace': deinterlace,
        'frameDrop': frameDrop,
        'networkCaching': networkCaching,
        'networkCacheSize': networkCacheSize,
        'audioSync': audioSync,
        'audioDelay': audioDelay,
        'subtitleDelay': subtitleDelay,
        'showTimeRemaining': showTimeRemaining,
        'showBuffering': showBuffering,
        'showQuality': showQuality,
        'rememberPosition': rememberPosition,
        'autoPlayNext': autoPlayNext,
        'shuffleEnabled': shuffleEnabled,
        'autoHideControlsDelay': autoHideControlsDelay ?? 2000,
        if (selectedQuality != null) 'selectedQuality': selectedQuality,
        if (selectedAudioTrack != null)
          'selectedAudioTrack': selectedAudioTrack,
        if (selectedSubtitleTrack != null)
          'selectedSubtitleTrack': selectedSubtitleTrack,
        if (selectedVideoTrack != null)
          'selectedVideoTrack': selectedVideoTrack,
      };
      await prefs.setString(_prefsKey, jsonEncode(preferences));
    } catch (e) {
      debugPrint('Error saving advanced features preferences: $e');
    }
  }

  /// Load all advanced features preferences
  Future<Map<String, dynamic>> loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);
      if (prefsJson != null) {
        return jsonDecode(prefsJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading advanced features preferences: $e');
    }

    // Return defaults
    return {
      'hardwareAcceleration': true,
      'deinterlace': false,
      'frameDrop': true,
      'networkCaching': true,
      'networkCacheSize': 1000,
      'audioSync': true,
      'audioDelay': 0.0,
      'subtitleDelay': 0.0,
      'showTimeRemaining': true,
      'showBuffering': true,
      'showQuality': true,
      'rememberPosition': true,
      'autoPlayNext': true,
      'shuffleEnabled': false,
      'autoHideControlsDelay': 2000,
      'selectedQuality': 'Auto',
      'selectedAudioTrack': 'Default',
      'selectedSubtitleTrack': 'None',
      'selectedVideoTrack': 'Default',
    };
  }

  /// Apply hardware acceleration setting
  /// Note: This would need to be applied when initializing the video player
  Future<void> applyHardwareAcceleration(bool enabled) async {
    // This would typically require reinitializing the video player
    // with the appropriate decoder settings
    debugPrint('Hardware acceleration: ${enabled ? "enabled" : "disabled"}');
  }

  /// Apply network caching settings
  /// Note: This would need to be applied when initializing the video player
  Future<void> applyNetworkCaching(bool enabled, int cacheSizeMs) async {
    debugPrint(
        'Network caching: ${enabled ? "enabled" : "disabled"}, size: ${cacheSizeMs}ms');
  }
}
