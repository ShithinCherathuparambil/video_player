import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/core/error/exceptions.dart';
import 'package:awesome_video_player/core/security/path_validator.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';

abstract class VideoLocalDataSource {
  Future<List<VideoFile>> getVideos();
  Future<void> requestPermissions();
}

// Custom exception for permission issues
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final Directory? _directory;

  VideoLocalDataSourceImpl({Directory? directory}) : _directory = directory;

  @override
  Future<List<VideoFile>> getVideos() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return await _getPlatformVideos();
      } else {
        return await _getLocalVideos();
      }
    } catch (e) {
      throw CacheException();
    }
  }

  Future<List<VideoFile>> _getPlatformVideos() async {
    final List<VideoFile> videos = [];

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();

      if (!ps.hasAccess) {
        throw PermissionDeniedException(
            'Photo library permission not granted. Please grant permission in settings.');
      }

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );

      if (paths.isEmpty) {
        return videos; // No video albums found
      }

      final AssetPathEntity recentPath = paths.first;

      final List<AssetEntity> entities = await recentPath.getAssetListPaged(
        page: 0,
        size: 100, // Increased to get more videos
      );

      for (int i = 0; i < entities.length; i++) {
        final entity = entities[i];

        if (entity.type == AssetType.video) {
          final file = await entity.file;
          if (file != null && PathValidator.isValidVideoPath(file.path)) {
            // Only generate thumbnail for the first 10 videos to improve loading speed
            String? thumbnailPath;
            Duration? duration;
            if (videos.length < 10) {
              // Generate thumbnail and duration in parallel for better performance
              final results = await Future.wait([
                _generateThumbnail(file.path),
                _extractVideoDuration(file.path),
              ]);
              thumbnailPath = results[0] as String?;
              duration = results[1] as Duration?;
            }

            // Validate thumbnail path for security
            if (thumbnailPath != null &&
                !PathValidator.isValidThumbnailPath(thumbnailPath)) {
              thumbnailPath = null;
            }

            final videoFile = VideoFile(
              path: file.path,
              name: PathValidator.getSecureFileName(file.path),
              thumbnailPath: thumbnailPath,
              duration: duration,
              fileSize: await file.length(),
              dateAdded: entity.createDateTime,
            );

            videos.add(videoFile);
          }
        }
      }
    } catch (e) {
      if (e is PermissionDeniedException) {
        rethrow; // Re-throw permission exceptions
      }
      throw CacheException('Failed to load videos: $e');
    }
    return videos;
  }

  Future<List<VideoFile>> _getLocalVideos() async {
    final List<VideoFile> videos = [];
    final directory = _directory ?? await getApplicationDocumentsDirectory();

    try {
      final List<FileSystemEntity> files = directory.listSync(recursive: true);
      for (var file in files) {
        if (file is File && _isVideoFile(file.path)) {
          final thumbnailPath = await _generateThumbnail(file.path);
          final duration = await _extractVideoDuration(file.path);
          final videoFile = VideoFile(
            path: file.path,
            name: path.basename(file.path),
            thumbnailPath: thumbnailPath,
            duration: duration,
            fileSize: await file.length(),
            dateAdded: await file.lastModified(),
          );
          videos.add(videoFile);
        }
      }
    } catch (e) {
      // Log error in debug mode only
      assert(() {
        debugPrint('Error getting videos: $e');
        return true;
      }());
    }
    return videos;
  }

  bool _isVideoFile(String filePath) {
    // Use secure path validation
    return PathValidator.isValidVideoPath(filePath);
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      final thumbnailDir = await getTemporaryDirectory();
      final thumbnailPath =
          '${thumbnailDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 120, // Reduced from 150 for faster generation
        quality: 30, // Reduced from 50 for faster generation
        timeMs: 1000, // Generate thumbnail at 1 second mark for consistency
      );

      return thumbnail;
    } catch (e) {
      return null;
    }
  }

  Future<Duration?> _extractVideoDuration(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));

      // Add timeout to prevent hanging on problematic videos
      await controller.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          controller.dispose();
        },
      );

      final videoDuration = controller.value.duration;
      await controller.dispose();
      return videoDuration;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final PermissionState ps = await PhotoManager.requestPermissionExtend();
        if (!ps.hasAccess) {
          throw PermissionDeniedException(
              'Photo library permission not granted.');
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  // Debug method to check permission status
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final PermissionState ps = await PhotoManager.requestPermissionExtend();
        return ps.hasAccess;
      } catch (e) {
        return false;
      }
    }
    return true; // For non-mobile platforms
  }
}
