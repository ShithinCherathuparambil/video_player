import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lumeo/domain/entities/subtitle.dart';
import 'package:lumeo/core/parsers/srt_parser.dart';
import 'package:lumeo/core/parsers/vtt_parser.dart';
import 'package:lumeo/core/parsers/ass_parser.dart';

/// Service for editing subtitles
class SubtitleEditorService {
  List<Subtitle> _subtitles = [];
  String _format = 'srt';

  /// Load subtitle file for editing
  Future<bool> loadSubtitleFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      final extension = filePath.split('.').last.toLowerCase();
      _format = extension;

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
          return false;
      }

      _subtitles = parsed;
      return true;
    } catch (e) {
      debugPrint('Error loading subtitle file: $e');
      return false;
    }
  }

  /// Get all subtitles
  List<Subtitle> getSubtitles() {
    return List.unmodifiable(_subtitles);
  }

  /// Update subtitle text
  void updateSubtitle(int index, String newText) {
    if (index >= 0 && index < _subtitles.length) {
      final subtitle = _subtitles[index];
      _subtitles[index] = Subtitle(
        startTime: subtitle.startTime,
        endTime: subtitle.endTime,
        text: newText,
        styles: subtitle.styles,
      );
    }
  }

  /// Update subtitle timing
  void updateSubtitleTiming(int index, Duration startTime, Duration endTime) {
    if (index >= 0 && index < _subtitles.length) {
      final subtitle = _subtitles[index];
      _subtitles[index] = Subtitle(
        startTime: startTime,
        endTime: endTime,
        text: subtitle.text,
        styles: subtitle.styles,
      );
    }
  }

  /// Add new subtitle
  void addSubtitle(Duration startTime, Duration endTime, String text) {
    _subtitles.add(Subtitle(
      startTime: startTime,
      endTime: endTime,
      text: text,
    ));
    _subtitles.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Remove subtitle
  void removeSubtitle(int index) {
    if (index >= 0 && index < _subtitles.length) {
      _subtitles.removeAt(index);
    }
  }

  /// Save subtitle file
  Future<bool> saveSubtitleFile(String filePath) async {
    try {
      final content = _formatSubtitleContent();
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('Error saving subtitle file: $e');
      return false;
    }
  }

  /// Format subtitle content based on format
  String _formatSubtitleContent() {
    switch (_format) {
      case 'srt':
        return _formatSrt();
      case 'vtt':
        return _formatVtt();
      case 'ass':
      case 'ssa':
        return _formatAss();
      default:
        return _formatSrt();
    }
  }

  /// Format as SRT
  String _formatSrt() {
    final buffer = StringBuffer();
    for (var i = 0; i < _subtitles.length; i++) {
      final subtitle = _subtitles[i];
      buffer.writeln(i + 1);
      buffer.writeln('${_formatTimecode(subtitle.startTime)} --> ${_formatTimecode(subtitle.endTime)}');
      buffer.writeln(subtitle.text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Format as VTT
  String _formatVtt() {
    final buffer = StringBuffer();
    buffer.writeln('WEBVTT');
    buffer.writeln();
    for (final subtitle in _subtitles) {
      buffer.writeln('${_formatTimecodeVtt(subtitle.startTime)} --> ${_formatTimecodeVtt(subtitle.endTime)}');
      buffer.writeln(subtitle.text);
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Format as ASS
  String _formatAss() {
    final buffer = StringBuffer();
    buffer.writeln('[Script Info]');
    buffer.writeln('Title: Edited Subtitles');
    buffer.writeln();
    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');
    for (final subtitle in _subtitles) {
      buffer.writeln('Dialogue: 0,${_formatTimecodeAss(subtitle.startTime)},${_formatTimecodeAss(subtitle.endTime)},Default,,0,0,0,,${subtitle.text}');
    }
    return buffer.toString();
  }

  String _formatTimecode(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  String _formatTimecodeVtt(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$milliseconds';
  }

  String _formatTimecodeAss(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final centiseconds = (duration.inMilliseconds % 1000) ~/ 10;
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }
}

