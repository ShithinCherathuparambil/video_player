import 'package:awesome_video_player/domain/repositories/settings_repository.dart';

class GetSubtitlesEnabled {
  final SettingsRepository repository;

  GetSubtitlesEnabled(this.repository);

  /// Executes the use case to retrieve subtitle preferences.
  Future<bool> call() async {
    final settings = await repository.getSettings();
    return settings.subtitlesEnabled;
  }
}
