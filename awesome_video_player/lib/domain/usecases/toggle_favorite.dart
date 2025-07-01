import 'package:lumeo/domain/repositories/video_repository.dart';

class ToggleFavorite {
  final VideoRepository repository;

  ToggleFavorite(this.repository);

  Future<void> call(String videoPath) async {
    return await repository.toggleFavorite(videoPath);
  }
}
