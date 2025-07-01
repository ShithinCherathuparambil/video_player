import 'package:lumeo/domain/entities/video_file.dart';

abstract class VideoRepository {
  /// Fetches a list of video files.
  ///
  /// Throws an exception if an error occurs during fetching (e.g., permission issues, network errors if applicable).
  Future<List<VideoFile>> getVideos();

  /// Saves video metadata including playback position and status.
  ///
  /// Throws an exception if saving fails.
  Future<void> saveVideoMetadata(VideoFile video);

  /// Toggles the favorite status of a video.
  ///
  /// Throws an exception if toggling fails.
  Future<void> toggleFavorite(String videoPath);

  /// Fetches a list of favorite videos.
  ///
  /// Throws an exception if an error occurs during fetching (e.g., permission issues, network errors if applicable).
  Future<List<VideoFile>> getFavoriteVideos();

  // Future<VideoFile> getVideoDetails(String videoId); // Example for future extension
}
