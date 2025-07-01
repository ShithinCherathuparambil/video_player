import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';

class GetFavoriteVideos {
  final VideoRepository repository;

  GetFavoriteVideos(this.repository);

  Future<List<VideoFile>> call() async {
    return await repository.getFavoriteVideos();
  }
}
