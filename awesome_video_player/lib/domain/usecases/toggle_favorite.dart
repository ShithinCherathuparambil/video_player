import 'package:awesome_video_player/domain/repositories/video_repository.dart';

class ToggleFavorite {
  final VideoRepository repository;

  ToggleFavorite(this.repository);

  Future<void> call(String videoPath) async {
    return await repository.toggleFavorite(videoPath);
  }
}
