import 'package:flutter/foundation.dart';

/// Stream quality information
class StreamQuality {
  final String label;
  final String url;
  final int? width;
  final int? height;
  final int? bitrate;

  const StreamQuality({
    required this.label,
    required this.url,
    this.width,
    this.height,
    this.bitrate,
  });
}

/// Service for managing network streaming
class NetworkStreamService {
  /// Detect stream type from URL
  StreamType detectStreamType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.m3u8')) {
      return StreamType.hls;
    } else if (lowerUrl.contains('.mpd')) {
      return StreamType.dash;
    } else if (lowerUrl.startsWith('rtsp://')) {
      return StreamType.rtsp;
    } else if (lowerUrl.startsWith('rtmp://')) {
      return StreamType.rtmp;
    } else if (lowerUrl.startsWith('http://') || lowerUrl.startsWith('https://')) {
      return StreamType.http;
    }
    return StreamType.unknown;
  }

  /// Parse HLS playlist to get available qualities
  Future<List<StreamQuality>> parseHlsPlaylist(String playlistUrl) async {
    try {
      // TODO: Implement HLS playlist parsing
      // This would parse the .m3u8 file to extract quality variants
      debugPrint('Parsing HLS playlist: $playlistUrl');
      return [];
    } catch (e) {
      debugPrint('Error parsing HLS playlist: $e');
      return [];
    }
  }

  /// Parse DASH manifest to get available qualities
  Future<List<StreamQuality>> parseDashManifest(String manifestUrl) async {
    try {
      // TODO: Implement DASH manifest parsing
      debugPrint('Parsing DASH manifest: $manifestUrl');
      return [];
    } catch (e) {
      debugPrint('Error parsing DASH manifest: $e');
      return [];
    }
  }

  /// Get best quality stream
  StreamQuality? getBestQuality(List<StreamQuality> qualities) {
    if (qualities.isEmpty) return null;
    
    // Sort by resolution/bitrate (highest first)
    qualities.sort((a, b) {
      final aRes = (a.width ?? 0) * (a.height ?? 0);
      final bRes = (b.width ?? 0) * (b.height ?? 0);
      return bRes.compareTo(aRes);
    });
    
    return qualities.first;
  }
}

enum StreamType {
  hls,
  dash,
  rtsp,
  rtmp,
  http,
  unknown,
}

