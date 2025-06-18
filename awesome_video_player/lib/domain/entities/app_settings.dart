import 'package:flutter/material.dart'; // For ThemeMode

// Entity representing application settings
class AppSettings {
  final ThemeMode themeMode;
  final bool? isGridView;
  final bool subtitlesEnabled;
  final String videoDecoder; // Add video decoder setting
  final bool hardwareAcceleration; // Add hardware acceleration setting
  // Add other app-specific settings here in the future
  // final String languageCode;
  // final bool notificationsEnabled;

  AppSettings({
    required this.themeMode,
    this.isGridView,
    this.subtitlesEnabled = true, // Default to enabled
    this.videoDecoder = 'auto', // Default to auto
    this.hardwareAcceleration = true, // Default to enabled
    // this.languageCode = 'en', // Default language
    // this.notificationsEnabled = true, // Default notification setting
  });

  // Optional: Implement copyWith for easier updates if the entity grows
  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? isGridView,
    bool? subtitlesEnabled,
    String? videoDecoder,
    bool? hardwareAcceleration,
    // String? languageCode,
    // bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      isGridView: isGridView ?? this.isGridView,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
      videoDecoder: videoDecoder ?? this.videoDecoder,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      // languageCode: languageCode ?? this.languageCode,
      // notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  // Optional: Implement Equatable for easier comparison
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          themeMode == other.themeMode &&
          isGridView == other.isGridView &&
          subtitlesEnabled == other.subtitlesEnabled &&
          videoDecoder == other.videoDecoder &&
          hardwareAcceleration == other.hardwareAcceleration;
  // && languageCode == other.languageCode
  // && notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode =>
      themeMode.hashCode ^
      isGridView.hashCode ^
      subtitlesEnabled.hashCode ^
      videoDecoder.hashCode ^
      hardwareAcceleration.hashCode;
  // ^ languageCode.hashCode
  // ^ notificationsEnabled.hashCode;
}
