import 'package:lumeo/domain/repositories/video_repository.dart';

class DeleteVideo {
  final VideoRepository repository;

  DeleteVideo(this.repository);

  /// Executes the use case to delete a video file.
  Future<void> call(String videoPath) async {
    return await repository.deleteVideo(videoPath);
  }
}
