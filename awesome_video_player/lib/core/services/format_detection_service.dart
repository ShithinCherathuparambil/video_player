import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lumeo/core/constants/video_formats.dart';

/// Video codec information
class VideoCodec {
  final String name;
  final bool supportsHardwareDecoding;
  final bool requiresVLC;

  const VideoCodec({
    required this.name,
    this.supportsHardwareDecoding = true,
    this.requiresVLC = false,
  });
}

/// Format detection result
class FormatDetectionResult {
  final String format;
  final String? codec;
  final bool isNetworkStream;
  final bool supportsHardwareDecoding;
  final bool requiresVLC;
  final String? streamType;

  const FormatDetectionResult({
    required this.format,
    this.codec,
    this.isNetworkStream = false,
    this.supportsHardwareDecoding = true,
    this.requiresVLC = false,
    this.streamType,
  });
}

/// Service for detecting video formats and selecting appropriate decoders
class FormatDetectionService {
  /// Detect video format from file path or URL
  Future<FormatDetectionResult> detectFormat(String pathOrUrl) async {
    // Check if it's a network stream
    if (_isNetworkStream(pathOrUrl)) {
      return _detectNetworkStream(pathOrUrl);
    }

    // Check if it's a content:// URI (Android content provider)
    if (pathOrUrl.startsWith('content://')) {
      return _detectLocalFile(pathOrUrl);
    }

    // Check if it's a local file
    final file = File(pathOrUrl);
    if (await file.exists()) {
      return _detectLocalFile(pathOrUrl);
    }

    // Default: assume MP4
    return const FormatDetectionResult(
      format: 'mp4',
      supportsHardwareDecoding: true,
      requiresVLC: false,
    );
  }

  /// Check if path is a network stream
  bool _isNetworkStream(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('rtsp://') ||
        path.startsWith('rtmp://');
  }

  /// Detect network stream type
  FormatDetectionResult _detectNetworkStream(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('.m3u8')) {
      return const FormatDetectionResult(
        format: 'm3u8',
        isNetworkStream: true,
        streamType: 'HLS',
        supportsHardwareDecoding: true,
        requiresVLC: false,
      );
    } else if (lowerUrl.contains('.mpd')) {
      return const FormatDetectionResult(
        format: 'mpd',
        isNetworkStream: true,
        streamType: 'DASH',
        supportsHardwareDecoding: true,
        requiresVLC: false,
      );
    } else if (lowerUrl.startsWith('rtsp://')) {
      return const FormatDetectionResult(
        format: 'rtsp',
        isNetworkStream: true,
        streamType: 'RTSP',
        supportsHardwareDecoding: false,
        requiresVLC: true,
      );
    } else if (lowerUrl.startsWith('rtmp://')) {
      return const FormatDetectionResult(
        format: 'rtmp',
        isNetworkStream: true,
        streamType: 'RTMP',
        supportsHardwareDecoding: false,
        requiresVLC: true,
      );
    } else if (lowerUrl.startsWith('http://') || lowerUrl.startsWith('https://')) {
      // Progressive HTTP stream
      return FormatDetectionResult(
        format: _getExtensionFromUrl(url),
        isNetworkStream: true,
        streamType: 'HTTP',
        supportsHardwareDecoding: _supportsHardwareDecoding(_getExtensionFromUrl(url)),
        requiresVLC: false,
      );
    }

    return const FormatDetectionResult(
      format: 'unknown',
      isNetworkStream: true,
      supportsHardwareDecoding: false,
      requiresVLC: true,
    );
  }

  /// Detect local file format
  FormatDetectionResult _detectLocalFile(String filePath) {
    final extension = _getExtension(filePath);
    final format = extension.toLowerCase();

    // Check if format is in supported list
    if (!VideoFormats.extensions.contains(format) &&
        !VideoFormats.streamingFormats.contains(format)) {
      debugPrint('Unknown video format: $format');
    }

    // Determine if VLC is required
    final requiresVLC = _requiresVLC(format);
    final supportsHardware = VideoFormats.supportsHardwareDecoding(format);

    return FormatDetectionResult(
      format: format,
      supportsHardwareDecoding: supportsHardware,
      requiresVLC: requiresVLC,
    );
  }

  /// Get file extension from path
  String _getExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last;
    }
    return '';
  }

  /// Get extension from URL
  String _getExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      return _getExtension(path);
    } catch (e) {
      return 'mp4'; // Default
    }
  }

  /// Check if format requires VLC player
  bool _requiresVLC(String format) {
    // Formats that typically require VLC
    const vlcRequiredFormats = [
      'avi',
      'flv',
      'rm',
      'rmvb',
      'vob',
      'asf',
      'divx',
      'xvid',
      'wmv',
      'mpg',
      'mpeg',
    ];

    return vlcRequiredFormats.contains(format.toLowerCase());
  }

  /// Check if format supports hardware decoding
  bool _supportsHardwareDecoding(String format) {
    return VideoFormats.supportsHardwareDecoding(format);
  }

  /// Get recommended player type
  PlayerType getRecommendedPlayer(FormatDetectionResult result) {
    if (result.requiresVLC) {
      return PlayerType.vlc;
    }

    if (result.isNetworkStream) {
      // For network streams, prefer better_player (supports HLS/DASH)
      if (result.format == 'm3u8' || result.format == 'mpd') {
        return PlayerType.betterPlayer;
      }
      // For RTSP/RTMP, use VLC
      if (result.format == 'rtsp' || result.format == 'rtmp') {
        return PlayerType.vlc;
      }
    }

    // For local files, prefer better_player if hardware decoding is supported
    if (result.supportsHardwareDecoding) {
      return PlayerType.betterPlayer;
    }

    // Fallback to VLC for unsupported formats
    return PlayerType.vlc;
  }

  /// Detect codec from file (simplified - would need actual file parsing)
  Future<String?> detectCodec(String filePath) async {
    // TODO: Implement actual codec detection using FFprobe or similar
    // For now, return null (codec will be detected by player)
    return null;
  }
}

/// Player type enum
enum PlayerType {
  betterPlayer,
  vlc,
  videoPlayer, // Fallback
}

