import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/repositories/settings_repository.dart';
import 'package:lumeo/data/datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<AppSettings> getSettings() async {
    // Fetch individual settings from the local data source
    final themeMode = await localDataSource.getThemeMode();
    final isGridView = await localDataSource.getGridViewPreference();
    final subtitlesEnabled = await localDataSource.getSubtitlesEnabled();
    // final languageCode = await localDataSource.getLanguageCode(); // Example
    // final notificationsEnabled = await localDataSource.getNotificationsEnabled(); // Example

    // Create and return the AppSettings entity
    return AppSettings(
      themeMode: themeMode,
      isGridView: isGridView,
      subtitlesEnabled: subtitlesEnabled,
      // languageCode: languageCode,
      // notificationsEnabled: notificationsEnabled,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    // Save individual settings to the local data source
    await localDataSource.saveThemeMode(settings.themeMode);
    if (settings.isGridView != null) {
      await localDataSource.saveGridViewPreference(settings.isGridView!);
    }
    await localDataSource.saveSubtitlesEnabled(settings.subtitlesEnabled);
    // await localDataSource.saveLanguageCode(settings.languageCode); // Example
    // await localDataSource.saveNotificationsEnabled(settings.notificationsEnabled); // Example
  }
}
