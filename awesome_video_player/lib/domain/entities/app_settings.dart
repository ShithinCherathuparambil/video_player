import 'package:flutter/material.dart'; // For ThemeMode

// Entity representing application settings
class AppSettings {
  final ThemeMode themeMode;
  // Add other app-specific settings here in the future
  // final String languageCode;
  // final bool notificationsEnabled;

  AppSettings({
    required this.themeMode,
    // this.languageCode = 'en', // Default language
    // this.notificationsEnabled = true, // Default notification setting
  });

  // Optional: Implement copyWith for easier updates if the entity grows
  AppSettings copyWith({
    ThemeMode? themeMode,
    // String? languageCode,
    // bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
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
          themeMode == other.themeMode;
          // && languageCode == other.languageCode
          // && notificationsEnabled == other.notificationsEnabled;

  @override
  int get hashCode => themeMode.hashCode;
                      // ^ languageCode.hashCode
                      // ^ notificationsEnabled.hashCode;
}
