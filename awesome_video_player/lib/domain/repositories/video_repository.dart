import 'package:awesome_video_player/domain/entities/video_file.dart';

abstract class VideoRepository {
  /// Fetches a list of video files.
  ///
  /// Throws an exception if an error occurs during fetching (e.g., permission issues, network errors if applicable).
  Future<List<VideoFile>> getVideos();

  // Future<VideoFile> getVideoDetails(String videoId); // Example for future extension
  // Future<void> saveVideoMetadata(VideoFile video); // Example for future extension
}
