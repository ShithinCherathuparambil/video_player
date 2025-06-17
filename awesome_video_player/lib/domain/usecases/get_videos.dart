import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';

class GetVideos {
  final VideoRepository _repository;

  GetVideos(this._repository);

  /// Executes the use case to retrieve a list of video files.
  Future<List<VideoFile>> call() async {
    return await _repository.getVideos();
  }
}
