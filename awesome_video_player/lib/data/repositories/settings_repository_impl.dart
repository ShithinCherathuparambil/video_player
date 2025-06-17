import 'package:flutter/material.dart' show ThemeMode; // For ThemeMode
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/repositories/settings_repository.dart';
import 'package:awesome_video_player/data/datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<AppSettings> getSettings() async {
    // Fetch individual settings from the local data source
    final themeMode = await localDataSource.getThemeMode();
    // final languageCode = await localDataSource.getLanguageCode(); // Example
    // final notificationsEnabled = await localDataSource.getNotificationsEnabled(); // Example

    // Create and return the AppSettings entity
    return AppSettings(
      themeMode: themeMode,
      // languageCode: languageCode,
      // notificationsEnabled: notificationsEnabled,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    // Save individual settings to the local data source
    await localDataSource.saveThemeMode(settings.themeMode);
    // await localDataSource.saveLanguageCode(settings.languageCode); // Example
    // await localDataSource.saveNotificationsEnabled(settings.notificationsEnabled); // Example
  }
}
