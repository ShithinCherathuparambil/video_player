import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Service to handle video file intents from other apps
class VideoIntentService {
  static const MethodChannel _channel = MethodChannel('com.example.awesome_video_player_fresh/video_intent');

  /// Get the video path from an incoming intent
  /// Returns null if no video was shared
  static Future<String?> getInitialVideoPath() async {
    try {
      if (Platform.isAndroid) {
        final String? videoPath = await _channel.invokeMethod<String>('getInitialVideoPath');
        return videoPath;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting initial video path: $e');
      return null;
    }
  }

  /// Convert content:// URI to file path if possible
  static Future<String?> resolveContentUri(String uriString) async {
    try {
      if (Platform.isAndroid) {
        // For content:// URIs, we'll need to use a plugin or handle it in native code
        // For now, return the URI string - the video player service can handle it
        return uriString;
      }
      return uriString;
    } catch (e) {
      debugPrint('Error resolving content URI: $e');
      return null;
    }
  }

  /// Copy a content:// URI to cache as a fallback when direct playback fails
  static Future<String?> copyContentUriToCache(String uriString) async {
    try {
      debugPrint('VideoIntentService: copyContentUriToCache called with: $uriString');
      if (Platform.isAndroid) {
        debugPrint('VideoIntentService: Invoking method channel copyContentUriToCache...');
        final String? cachedPath = await _channel.invokeMethod<String>(
          'copyContentUriToCache',
          {'uri': uriString},
        );
        debugPrint('VideoIntentService: Method channel returned: $cachedPath');
        return cachedPath;
      }
      debugPrint('VideoIntentService: Not Android platform, returning null');
      return null;
    } catch (e, stackTrace) {
      debugPrint('VideoIntentService: Error copying content URI to cache: $e');
      debugPrint('VideoIntentService: Stack trace: $stackTrace');
      return null;
    }
  }
}

