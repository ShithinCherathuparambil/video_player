import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';

class SaveVideoMetadata {
  final VideoRepository repository;

  SaveVideoMetadata(this.repository);

  /// Executes the use case to save video metadata.
  Future<void> call(VideoFile video) async {
    return await repository.saveVideoMetadata(video);
  }
}
