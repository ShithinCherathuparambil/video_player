import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';

class SaveVideoMetadata {
  final VideoRepository repository;

  SaveVideoMetadata(this.repository);

  /// Executes the use case to save video metadata.
  Future<void> call(VideoFile video) async {
    return await repository.saveVideoMetadata(video);
  }
}
