import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lumeo/domain/entities/subtitle.dart';
import 'package:lumeo/core/parsers/srt_parser.dart';
import 'package:lumeo/core/parsers/vtt_parser.dart';
import 'package:lumeo/core/parsers/ass_parser.dart';

/// Service for managing subtitles
class SubtitleService {
  List<Subtitle> _subtitles = [];
  int _delayMs = 0;

  /// Load subtitles from file
  Future<List<Subtitle>> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Subtitle file not found: $filePath');
        return [];
      }

      final extension = filePath.split('.').last.toLowerCase();
      List<Subtitle> parsed;

      switch (extension) {
        case 'srt':
          parsed = await SrtParser.parseFile(filePath);
          break;
        case 'vtt':
          parsed = await VttParser.parseFile(filePath);
          break;
        case 'ass':
        case 'ssa':
          parsed = await AssParser.parseFile(filePath);
          break;
        default:
          debugPrint('Unsupported subtitle format: $extension');
          return [];
      }

      _subtitles = parsed;
      return parsed;
    } catch (e) {
      debugPrint('Error loading subtitle file: $e');
      return [];
    }
  }

  /// Load subtitles from content string
  Future<List<Subtitle>> loadFromContent(String content, String format) async {
    try {
      List<Subtitle> parsed;

      switch (format.toLowerCase()) {
        case 'srt':
          parsed = SrtParser.parse(content);
          break;
        case 'vtt':
          parsed = VttParser.parse(content);
          break;
        case 'ass':
        case 'ssa':
          parsed = AssParser.parse(content);
          break;
        default:
          debugPrint('Unsupported subtitle format: $format');
          return [];
      }

      _subtitles = parsed;
      return parsed;
    } catch (e) {
      debugPrint('Error parsing subtitle content: $e');
      return [];
    }
  }

  /// Get subtitle at current time (with delay applied)
  Subtitle? getSubtitleAt(Duration currentTime) {
    final adjustedTime = currentTime + Duration(milliseconds: _delayMs);
    
    for (final subtitle in _subtitles) {
      if (subtitle.isActiveAt(adjustedTime)) {
        return subtitle;
      }
    }
    
    return null;
  }

  /// Get all subtitles
  List<Subtitle> getSubtitles() {
    return List.unmodifiable(_subtitles);
  }

  /// Set delay in milliseconds
  void setDelay(int delayMs) {
    _delayMs = delayMs;
  }

  /// Get current delay
  int getDelay() {
    return _delayMs;
  }

  /// Clear subtitles
  void clear() {
    _subtitles = [];
    _delayMs = 0;
  }

  /// Find subtitle file for a video file
  static Future<String?> findSubtitleFile(String videoPath) async {
    final videoFile = File(videoPath);
    if (!await videoFile.exists()) {
      return null;
    }

    final basePath = videoPath.substring(0, videoPath.lastIndexOf('.'));
    final extensions = ['srt', 'vtt', 'ass', 'ssa'];

    for (final ext in extensions) {
      final subtitlePath = '$basePath.$ext';
      final subtitleFile = File(subtitlePath);
      if (await subtitleFile.exists()) {
        return subtitlePath;
      }
    }

    return null;
  }

  /// Auto-detect and load subtitle for a video
  Future<List<Subtitle>> autoLoadForVideo(String videoPath) async {
    final subtitlePath = await findSubtitleFile(videoPath);
    if (subtitlePath != null) {
      return await loadFromFile(subtitlePath);
    }
    return [];
  }

  /// Load subtitle from network URL
  Future<List<Subtitle>> loadFromUrl(String url, String format) async {
    try {
      // TODO: Implement network subtitle loading when http package is added
      // final response = await http.get(Uri.parse(url));
      // if (response.statusCode == 200) {
      //   return await loadFromContent(response.body, format);
      // }
      debugPrint('Loading subtitle from URL: $url');
      return [];
    } catch (e) {
      debugPrint('Error loading subtitle from URL: $e');
      return [];
    }
  }
}

