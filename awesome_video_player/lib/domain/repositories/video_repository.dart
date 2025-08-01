import 'package:lumeo/domain/entities/video_file.dart';

abstract class VideoRepository {
  /// Fetches a list of video files.
  ///
  /// [page] The page number to fetch, starting from 0
  /// [pageSize] The number of videos to fetch per page
  ///
  /// Throws an exception if an error occurs during fetching (e.g., permission issues, network errors if applicable).
  Future<List<VideoFile>> getVideos({int page = 0, int pageSize = 20});

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

  /// Deletes a video file from the device storage.
  ///
  /// Throws an exception if deletion fails (e.g., permission issues, file not found).
  Future<void> deleteVideo(String videoPath);

  // Future<VideoFile> getVideoDetails(String videoId); // Example for future extension
}
