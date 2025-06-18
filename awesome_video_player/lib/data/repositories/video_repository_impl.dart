import 'dart:io'; // For File
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';

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
      print('VideoRepository: Starting to get videos...');

      // Return cached videos if available
      if (_cachedVideos != null) {
        print(
            'VideoRepository: Returning ${_cachedVideos!.length} cached videos');
        return _cachedVideos!;
      }

      print('VideoRepository: Requesting permissions...');
      await localDataSource.requestPermissions();
      print(
          'VideoRepository: Permissions granted, getting videos from data source...');

      final videos = await localDataSource.getVideos();
      print('VideoRepository: Got ${videos.length} videos from data source');

      // Load metadata for each video
      print('VideoRepository: Loading metadata for videos...');
      final videosWithMetadata = await _loadVideoMetadata(videos);
      print(
          'VideoRepository: Loaded metadata for ${videosWithMetadata.length} videos');

      // Cache the result for future use
      _cachedVideos = videosWithMetadata;
      print('VideoRepository: Cached ${_cachedVideos!.length} videos');

      return videosWithMetadata;
    } catch (e) {
      print('VideoRepository: Error loading videos: $e');
      print('VideoRepository: Error type: ${e.runtimeType}');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  @override
  Future<void> saveVideoMetadata(VideoFile video) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataMap = prefs.getString(_videoMetadataKey);
      Map<String, dynamic> allMetadata = {};

      if (metadataMap != null) {
        allMetadata = json.decode(metadataMap) as Map<String, dynamic>;
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

      await prefs.setString(_videoMetadataKey, json.encode(allMetadata));

      // Update cache and clear video cache to ensure consistency
      _metadataCache = allMetadata;
      _cachedVideos = null;
    } catch (e) {
      print('Error saving video metadata: $e');
      // Don't rethrow to prevent app crashes
    }
  }

  @override
  Future<void> toggleFavorite(String videoPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataMap = prefs.getString(_videoMetadataKey);
      Map<String, dynamic> allMetadata = {};

      if (metadataMap != null) {
        allMetadata = json.decode(metadataMap) as Map<String, dynamic>;
      }

      // Get current video metadata
      final videoData = allMetadata[videoPath];
      if (videoData != null) {
        // Toggle favorite status
        final currentFavorite = videoData['isFavorite'] as bool? ?? false;
        videoData['isFavorite'] = !currentFavorite;
        allMetadata[videoPath] = videoData;

        print('Toggled favorite for video: $videoPath to ${!currentFavorite}');
      } else {
        // Create new metadata entry if it doesn't exist
        allMetadata[videoPath] = {
          'path': videoPath,
          'name': videoPath.split('/').last,
          'isFavorite': true,
          'status': VideoStatus.new_.index,
        };
        print('Created new favorite entry for video: $videoPath');
      }

      await prefs.setString(_videoMetadataKey, json.encode(allMetadata));

      // Update cache and clear video cache to ensure consistency
      _metadataCache = allMetadata;
      _cachedVideos = null;
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  @override
  Future<List<VideoFile>> getFavoriteVideos() async {
    try {
      final allVideos = await getVideos();
      return allVideos.where((video) => video.isFavorite).toList();
    } catch (e) {
      print('Error getting favorite videos: $e');
      return [];
    }
  }

  Future<List<VideoFile>> _loadVideoMetadata(List<VideoFile> videos) async {
    try {
      // Use cached metadata if available
      Map<String, dynamic> allMetadata;

      if (_metadataCache != null) {
        allMetadata = _metadataCache!;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final metadataMap = prefs.getString(_videoMetadataKey);

        if (metadataMap == null) {
          _metadataCache = {};
          return videos;
        }

        allMetadata = json.decode(metadataMap) as Map<String, dynamic>;
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
