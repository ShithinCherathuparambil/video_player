import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing video playback positions
/// Allows users to resume videos where they left off
class PlaybackPositionService {
  static const String _positionKeyPrefix = 'playback_position_';
  static const String _lastWatchedKeyPrefix = 'last_watched_';

  /// Save playback position for a video
  Future<void> savePosition(String videoPath, Duration position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_positionKeyPrefix${videoPath.hashCode}';
      await prefs.setInt(key, position.inMilliseconds);
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Error saving playback position: $e');
    }
  }

  /// Get saved playback position for a video
  Future<Duration?> getPosition(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_positionKeyPrefix${videoPath.hashCode}';
      final milliseconds = prefs.getInt(key);
      return milliseconds != null ? Duration(milliseconds: milliseconds) : null;
    } catch (e) {
      debugPrint('Error getting playback position: $e');
      return null;
    }
  }

  /// Clear saved position for a video
  Future<void> clearPosition(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_positionKeyPrefix${videoPath.hashCode}';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error clearing playback position: $e');
    }
  }

  /// Save last watched timestamp
  Future<void> saveLastWatched(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_lastWatchedKeyPrefix${videoPath.hashCode}';
      await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving last watched: $e');
    }
  }

  /// Get last watched timestamp
  Future<DateTime?> getLastWatched(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_lastWatchedKeyPrefix${videoPath.hashCode}';
      final timestamp = prefs.getInt(key);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('Error getting last watched: $e');
      return null;
    }
  }

  /// Get all videos with saved positions (for continue watching)
  Future<Map<String, Duration>> getAllPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final positions = <String, Duration>{};
      
      for (final key in keys) {
        if (key.startsWith(_positionKeyPrefix)) {
          final milliseconds = prefs.getInt(key);
          if (milliseconds != null) {
            // Extract video path hash from key
            final hashStr = key.substring(_positionKeyPrefix.length);
            positions[hashStr] = Duration(milliseconds: milliseconds);
          }
        }
      }
      
      return positions;
    } catch (e) {
      debugPrint('Error getting all positions: $e');
      return {};
    }
  }

  /// Get recently watched videos (sorted by last watched time)
  Future<List<MapEntry<String, DateTime>>> getRecentlyWatched({int limit = 20}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final watched = <MapEntry<String, DateTime>>[];
      
      for (final key in keys) {
        if (key.startsWith(_lastWatchedKeyPrefix)) {
          final timestamp = prefs.getInt(key);
          if (timestamp != null) {
            final hashStr = key.substring(_lastWatchedKeyPrefix.length);
            watched.add(MapEntry(hashStr, DateTime.fromMillisecondsSinceEpoch(timestamp)));
          }
        }
      }
      
      // Sort by most recent first
      watched.sort((a, b) => b.value.compareTo(a.value));
      
      return watched.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recently watched: $e');
      return [];
    }
  }

  /// Clear all saved positions (for cleanup)
  Future<void> clearAllPositions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_positionKeyPrefix) ||
            key.startsWith(_lastWatchedKeyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing all positions: $e');
    }
  }
}

