import 'dart:io';
import 'package:lumeo/domain/entities/subtitle.dart';

/// Parser for ASS (Advanced SubStation Alpha) subtitle format
class AssParser {
  /// Parse ASS file content into list of Subtitle objects
  static List<Subtitle> parse(String content) {
    final subtitles = <Subtitle>[];
    final lines = content.split('\n');
    
    bool inEventsSection = false;
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Check if we're entering the Events section
      if (trimmed.startsWith('[Events]')) {
        inEventsSection = true;
        continue;
      }
      
      // Check if we're leaving the Events section
      if (inEventsSection && trimmed.startsWith('[') && !trimmed.startsWith('[Events]')) {
        inEventsSection = false;
        continue;
      }
      
      // Parse dialogue lines in Events section
      if (inEventsSection && trimmed.startsWith('Dialogue:')) {
        final subtitle = _parseDialogue(trimmed);
        if (subtitle != null) {
          subtitles.add(subtitle);
        }
      }
    }
    
    return subtitles;
  }

  /// Parse ASS file from path
  static Future<List<Subtitle>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return [];
    }
    
    final content = await file.readAsString();
    return parse(content);
  }

  /// Parse a Dialogue line
  /// Format: Dialogue: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
  static Subtitle? _parseDialogue(String line) {
    // Remove "Dialogue:" prefix
    var content = line.substring('Dialogue:'.length).trim();
    
    // Split by comma, but be careful with commas in the text
    final parts = <String>[];
    var currentPart = '';
    var inQuotes = false;
    
    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == ',' && !inQuotes) {
        parts.add(currentPart.trim());
        currentPart = '';
      } else if (char == '"') {
        inQuotes = !inQuotes;
        currentPart += char;
      } else {
        currentPart += char;
      }
    }
    parts.add(currentPart.trim()); // Add the last part (text)
    
    if (parts.length < 10) {
      return null;
    }
    
    // Parse times (format: 0:00:01.23)
    final startTime = _parseAssTime(parts[1]);
    final endTime = _parseAssTime(parts[2]);
    
    // Get text (last part, remove ASS styling tags)
    var text = parts[9];
    // Remove ASS override tags (basic removal)
    text = text.replaceAll(RegExp(r'\{[^}]+\}'), '');
    // Remove HTML-like tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Replace \N with newline
    text = text.replaceAll('\\N', '\n');
    text = text.replaceAll('\\n', '\n');
    
    if (text.isEmpty) {
      return null;
    }
    
    return Subtitle(
      startTime: startTime,
      endTime: endTime,
      text: text,
    );
  }

  /// Parse ASS time format (0:00:01.23) to Duration
  static Duration _parseAssTime(String timeStr) {
    // Format: H:MM:SS.cc or H:MM:SS:cc (colon or period for centiseconds)
    final match = RegExp(r'(\d+):(\d{2}):(\d{2})[.:](\d{2})').firstMatch(timeStr);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      final minutes = int.parse(match.group(2)!);
      final seconds = int.parse(match.group(3)!);
      final centiseconds = int.parse(match.group(4)!);
      
      return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: centiseconds * 10,
      );
    }
    
    return Duration.zero;
  }
}

