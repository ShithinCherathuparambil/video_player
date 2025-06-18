import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';

class GetFavoriteVideos {
  final VideoRepository repository;

  GetFavoriteVideos(this.repository);

  Future<List<VideoFile>> call() async {
    return await repository.getFavoriteVideos();
  }
}
