import 'package:equatable/equatable.dart';

/// Subtitle entity representing a single subtitle entry
class Subtitle extends Equatable {
  final Duration startTime;
  final Duration endTime;
  final String text;
  final Map<String, dynamic>? styles;

  const Subtitle({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.styles,
  });

  /// Check if subtitle is active at given time
  bool isActiveAt(Duration time) {
    return time >= startTime && time <= endTime;
  }

  /// Get duration of subtitle
  Duration get duration => endTime - startTime;

  @override
  List<Object?> get props => [startTime, endTime, text, styles];
}

/// Subtitle settings for customization
class SubtitleSettings extends Equatable {
  final double fontSize;
  final int textColor; // Color as int (for serialization)
  final int backgroundColor;
  final int outlineColor;
  final double outlineWidth;
  final String fontFamily;
  final double position; // 0.0 to 1.0 (bottom position)
  final double padding;
  final int delayMs; // Sync delay in milliseconds

  const SubtitleSettings({
    this.fontSize = 16.0,
    this.textColor = 0xFFFFFFFF, // White
    this.backgroundColor = 0x00000000, // Transparent
    this.outlineColor = 0xFF000000, // Black
    this.outlineWidth = 2.0,
    this.fontFamily = 'Roboto',
    this.position = 0.1,
    this.padding = 8.0,
    this.delayMs = 0,
  });

  SubtitleSettings copyWith({
    double? fontSize,
    int? textColor,
    int? backgroundColor,
    int? outlineColor,
    double? outlineWidth,
    String? fontFamily,
    double? position,
    double? padding,
    int? delayMs,
  }) {
    return SubtitleSettings(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineWidth: outlineWidth ?? this.outlineWidth,
      fontFamily: fontFamily ?? this.fontFamily,
      position: position ?? this.position,
      padding: padding ?? this.padding,
      delayMs: delayMs ?? this.delayMs,
    );
  }

  @override
  List<Object?> get props => [
        fontSize,
        textColor,
        backgroundColor,
        outlineColor,
        outlineWidth,
        fontFamily,
        position,
        padding,
        delayMs,
      ];
}

