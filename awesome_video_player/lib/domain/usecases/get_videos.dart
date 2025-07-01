import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';

class GetVideos {
  final VideoRepository repository;

  GetVideos(this.repository);

  /// Executes the use case to retrieve a list of video files.
  Future<List<VideoFile>> call() async {
    return await repository.getVideos();
  }
}
