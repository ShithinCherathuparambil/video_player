import 'dart:io'; // For File
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoLocalDataSource localDataSource;

  VideoRepositoryImpl({required this.localDataSource});

  @override
  Future<List<VideoFile>> getVideos() async {
    try {
      final List<String> videoPaths = await localDataSource.getVideoPaths();

      final List<VideoFile> videoFiles = videoPaths.map((path) {
        // Extract file name from path
        String name = path.split(Platform.pathSeparator).last;
        return VideoFile(path: path, name: name);
      }).toList();

      return videoFiles;
    } on PermissionDeniedException {
      // Propagate permission denied exception or handle as specific error/empty list
      print('Permission denied in VideoRepositoryImpl. Returning empty list or re-throwing.');
      return []; // Or rethrow;
    } catch (e) {
      // Handle other errors, e.g., file system errors
      print('Error in VideoRepositoryImpl getting videos: $e. Returning empty list.');
      return []; // Or rethrow specific domain error;
    }
  }
}
