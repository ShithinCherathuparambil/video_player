import 'dart:io';
import 'package:lumeo/domain/entities/subtitle.dart';

/// Parser for SRT (SubRip) subtitle format
class SrtParser {
  /// Parse SRT file content into list of Subtitle objects
  static List<Subtitle> parse(String content) {
    final subtitles = <Subtitle>[];
    final lines = content.split('\n');
    
    int index = 0;
    while (index < lines.length) {
      // Skip empty lines
      while (index < lines.length && lines[index].trim().isEmpty) {
        index++;
      }
      
      if (index >= lines.length) break;
      
      // Parse subtitle number (optional, we'll skip it)
      final numberLine = lines[index].trim();
      if (numberLine.isNotEmpty && int.tryParse(numberLine) != null) {
        index++;
      }
      
      if (index >= lines.length) break;
      
      // Parse timecode line (e.g., "00:00:01,234 --> 00:00:03,456")
      final timecodeLine = lines[index].trim();
      final timeMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})')
          .firstMatch(timecodeLine);
      
      if (timeMatch == null) {
        index++;
        continue;
      }
      
      final startTime = _parseTimecode(
        int.parse(timeMatch.group(1)!),
        int.parse(timeMatch.group(2)!),
        int.parse(timeMatch.group(3)!),
        int.parse(timeMatch.group(4)!),
      );
      
      final endTime = _parseTimecode(
        int.parse(timeMatch.group(5)!),
        int.parse(timeMatch.group(6)!),
        int.parse(timeMatch.group(7)!),
        int.parse(timeMatch.group(8)!),
      );
      
      index++;
      
      // Parse subtitle text (can be multiple lines)
      final textLines = <String>[];
      while (index < lines.length && lines[index].trim().isNotEmpty) {
        textLines.add(lines[index].trim());
        index++;
      }
      
      if (textLines.isNotEmpty) {
        final text = textLines.join('\n');
        subtitles.add(Subtitle(
          startTime: startTime,
          endTime: endTime,
          text: text,
        ));
      }
    }
    
    return subtitles;
  }

  /// Parse SRT file from path
  static Future<List<Subtitle>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return [];
    }
    
    final content = await file.readAsString();
    return parse(content);
  }

  /// Parse timecode to Duration
  static Duration _parseTimecode(int hours, int minutes, int seconds, int milliseconds) {
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }
}

