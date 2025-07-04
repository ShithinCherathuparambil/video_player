import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart';
import 'package:lumeo/core/security/secure_storage.dart';

class VideoRepositoryImpl implements VideoRepository {
  final VideoLocalDataSource localDataSource;
  static const String _videoMetadataKey = 'video_metadata';

  // Cache for video metadata to avoid repeated SharedPreferences access
  Map<String, dynamic>? _metadataCache;
  List<VideoFile>? _cachedVideos;

  VideoRepositoryImpl({required this.localDataSource});

  @override
  Future<List<VideoFile>> getVideos() async {
    try {
      // Return cached videos if available
      if (_cachedVideos != null) {
        return _cachedVideos!;
      }

      await localDataSource.requestPermissions();
      final videos = await localDataSource.getVideos();

      // Load metadata for each video
      final videosWithMetadata = await _loadVideoMetadata(videos);

      // Cache the result for future use
      _cachedVideos = videosWithMetadata;

      return videosWithMetadata;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        debugPrint('VideoRepository: Error loading videos: $e');
        return true;
      }());
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  @override
  Future<void> saveVideoMetadata(VideoFile video) async {
    try {
      // Use secure storage for sensitive metadata
      final metadataString =
          await SecureStorage.getSecureString(_videoMetadataKey);
      Map<String, dynamic> allMetadata = {};

      if (metadataString != null) {
        allMetadata = json.decode(metadataString) as Map<String, dynamic>;
      }

      // If this video is being marked as "watching", clear "watching" status from other videos
      if (video.status == VideoStatus.watching) {
        for (final entry in allMetadata.entries) {
          final videoData = entry.value as Map<String, dynamic>;
          if (videoData['status'] == VideoStatus.watching.index &&
              entry.key != video.path) {
            videoData['status'] = VideoStatus.watched.index;
            allMetadata[entry.key] = videoData;
          }
        }
      }

      // If this video is being marked as "lastWatched", clear "lastWatched" status from other videos
      if (video.status == VideoStatus.lastWatched) {
        for (final entry in allMetadata.entries) {
          final videoData = entry.value as Map<String, dynamic>;
          if (videoData['status'] == VideoStatus.lastWatched.index &&
              entry.key != video.path) {
            videoData['status'] = VideoStatus.watched.index;
            allMetadata[entry.key] = videoData;
          }
        }
      }

      // Save metadata for this video using path as key
      allMetadata[video.path] = video.toJson();

      await SecureStorage.setSecureString(
          _videoMetadataKey, json.encode(allMetadata));

      // Update cache and clear video cache to ensure consistency
      _metadataCache = allMetadata;
      _cachedVideos = null;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        debugPrint('Error saving video metadata: $e');
        return true;
      }());
      // Don't rethrow to prevent app crashes
    }
  }

  @override
  Future<void> toggleFavorite(String videoPath) async {
    try {
      final metadataString =
          await SecureStorage.getSecureString(_videoMetadataKey);
      Map<String, dynamic> allMetadata = {};

      if (metadataString != null) {
        allMetadata = json.decode(metadataString) as Map<String, dynamic>;
      }

      // Get current video metadata
      final videoData = allMetadata[videoPath];
      if (videoData != null) {
        // Toggle favorite status
        final currentFavorite = videoData['isFavorite'] as bool? ?? false;
        videoData['isFavorite'] = !currentFavorite;
        allMetadata[videoPath] = videoData;
      } else {
        // Create new metadata entry if it doesn't exist
        allMetadata[videoPath] = {
          'path': videoPath,
          'name': videoPath.split('/').last,
          'isFavorite': true,
          'status': VideoStatus.new_.index,
        };
      }

      await SecureStorage.setSecureString(
          _videoMetadataKey, json.encode(allMetadata));

      // Update cache and clear video cache to ensure consistency
      _metadataCache = allMetadata;
      _cachedVideos = null;
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        debugPrint('Error toggling favorite: $e');
        return true;
      }());
      rethrow;
    }
  }

  @override
  Future<List<VideoFile>> getFavoriteVideos() async {
    try {
      final allVideos = await getVideos();
      return allVideos.where((video) => video.isFavorite).toList();
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        debugPrint('Error getting favorite videos: $e');
        return true;
      }());
      return [];
    }
  }

  @override
  Future<void> deleteVideo(String videoPath) async {
    try {
      debugPrint('VideoRepositoryImpl: Starting deletion of video: $videoPath');

      // Delete the video file from storage
      await localDataSource.deleteVideo(videoPath);
      debugPrint(
          'VideoRepositoryImpl: Successfully deleted video file from storage');

      // Remove video metadata from secure storage
      final metadataString =
          await SecureStorage.getSecureString(_videoMetadataKey);
      if (metadataString != null) {
        debugPrint('VideoRepositoryImpl: Found metadata, removing video entry');
        Map<String, dynamic> allMetadata =
            json.decode(metadataString) as Map<String, dynamic>;

        // Remove the video's metadata
        final removed = allMetadata.remove(videoPath);
        debugPrint('VideoRepositoryImpl: Metadata removed: $removed');

        // Save updated metadata
        await SecureStorage.setSecureString(
            _videoMetadataKey, json.encode(allMetadata));
        debugPrint('VideoRepositoryImpl: Updated metadata saved');

        // Update cache
        _metadataCache = allMetadata;
      } else {
        debugPrint('VideoRepositoryImpl: No metadata found to remove');
      }

      // Clear video cache to force refresh
      _cachedVideos = null;
      debugPrint('VideoRepositoryImpl: Video cache cleared');
    } catch (e) {
      // Log error in debug mode only
      debugPrint('VideoRepositoryImpl: Error deleting video: $e');
      assert(() {
        debugPrint('Error deleting video: $e');
        return true;
      }());
      rethrow;
    }
  }

  Future<List<VideoFile>> _loadVideoMetadata(List<VideoFile> videos) async {
    try {
      // Use cached metadata if available
      Map<String, dynamic> allMetadata;

      if (_metadataCache != null) {
        allMetadata = _metadataCache!;
      } else {
        final metadataString =
            await SecureStorage.getSecureString(_videoMetadataKey);

        if (metadataString == null) {
          _metadataCache = {};
          return videos;
        }

        allMetadata = json.decode(metadataString) as Map<String, dynamic>;
        _metadataCache = allMetadata;
      }

      final List<VideoFile> videosWithMetadata = [];

      for (final video in videos) {
        final videoMetadata = allMetadata[video.path];
        if (videoMetadata != null) {
          // Merge metadata with video file
          final metadataVideo = VideoFile.fromJson(videoMetadata);
          videosWithMetadata.add(video.copyWith(
            lastPlayedPosition: metadataVideo.lastPlayedPosition,
            lastPlayedAt: metadataVideo.lastPlayedAt,
            status: metadataVideo.status,
            isFavorite: metadataVideo.isFavorite,
          ));
        } else {
          videosWithMetadata.add(video);
        }
      }

      return videosWithMetadata;
    } catch (e) {
      // If metadata loading fails, return original videos
      return videos;
    }
  }

  // Method to automatically refresh cache
  Future<void> refreshCache() async {
    _cachedVideos = null;
    _metadataCache = null;
    await getVideos(); // This will reload and cache everything
  }
}
