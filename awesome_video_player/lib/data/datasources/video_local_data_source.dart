import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lumeo/core/error/exceptions.dart';
import 'package:lumeo/core/security/path_validator.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:photo_manager/photo_manager.dart';
import 'package:lumeo/core/services/permission_service.dart';

abstract class VideoLocalDataSource {
  Future<List<VideoFile>> getVideos();
  Future<void> requestPermissions();
  Future<void> deleteVideo(String videoPath);
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
        assert(() {
          debugPrint('Permission not granted for photo library.');
          return true;
        }());
        throw PermissionDeniedException(
            'Photo library permission not granted. Please grant permission in settings.');
      }

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );

      if (paths.isEmpty) {
        assert(() {
          debugPrint('No video albums found.');
          return true;
        }());
        return videos; // No video albums found
      }

      final AssetPathEntity recentPath = paths.first;

      final List<AssetEntity> entities = await recentPath.getAssetListPaged(
        page: 0,
        size: 100, // Increased to get more videos
      );

      assert(() {
        debugPrint('Found \\${entities.length} video assets');
        return true;
      }());

      for (int i = 0; i < entities.length; i++) {
        final entity = entities[i];

        if (entity.type == AssetType.video) {
          final file = await entity.file;
          assert(() {
            debugPrint('Asset file path: \\${file?.path}');
            return true;
          }());
          final isValid =
              file != null ? PathValidator.isValidVideoPath(file.path) : false;
          assert(() {
            debugPrint('PathValidator.isValidVideoPath: \\$isValid');
            return true;
          }());
          if (file != null && (Platform.isIOS || isValid)) {
            // Only generate thumbnail for the first 10 videos to improve loading speed
            String? thumbnailPath;
            Uint8List? thumbnailBytes;
            Duration? duration;
            if (videos.length < 10) {
              if (Platform.isIOS) {
                // Use photo_manager's built-in thumbnail for iOS
                thumbnailBytes = await entity
                    .thumbnailDataWithSize(const ThumbnailSize(120, 120));
                duration = await _extractVideoDuration(file.path);
              } else {
                // Android: generate thumbnail file as before
                final results = await Future.wait([
                  _generateThumbnail(file.path),
                  _extractVideoDuration(file.path),
                ]);
                thumbnailPath = results[0] as String?;
                duration = results[1] as Duration?;
              }
            }

            // Validate thumbnail path for security
            if (thumbnailPath != null &&
                !PathValidator.isValidThumbnailPath(thumbnailPath)) {
              thumbnailPath = null;
            }

            final videoFile = VideoFile(
              path: file.path,
              name: (Platform.isIOS &&
                      entity.title != null &&
                      entity.title!.isNotEmpty)
                  ? entity.title!
                  : (path.basename(file.path).isNotEmpty
                      ? path.basename(file.path)
                      : 'Video'),
              thumbnailPath: thumbnailPath,
              thumbnailBytes: thumbnailBytes,
              duration: duration,
              fileSize: await file.length(),
              dateAdded: entity.createDateTime,
            );

            videos.add(videoFile);
          } else {
            assert(() {
              debugPrint('Skipped file: \\${file?.path} (invalid or null)');
              return true;
            }());
          }
        } else {
          assert(() {
            debugPrint('Skipped non-video asset');
            return true;
          }());
        }
      }
      assert(() {
        debugPrint('Returning \\${videos.length} valid videos');
        return true;
      }());
    } catch (e) {
      assert(() {
        debugPrint('Error in _getPlatformVideos: \\${e.toString()}');
        return true;
      }());
      if (e is PermissionDeniedException) {
        rethrow; // Re-throw permission exceptions
      }
      throw CacheException('Failed to load videos: \\${e.toString()}');
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

  @override
  Future<void> deleteVideo(String videoPath) async {
    try {
      debugPrint(
          'VideoLocalDataSource: Starting deletion of video: $videoPath');

      // Validate the path for security
      if (!PathValidator.isValidVideoPath(videoPath)) {
        throw Exception('Invalid video path: $videoPath');
      }
      debugPrint('VideoLocalDataSource: Path validation passed');

      // For Android 10+ (API 29+), we should use MediaStore for all deletions
      // This is the proper way to handle scoped storage
      debugPrint(
          'VideoLocalDataSource: Using MediaStore deletion for scoped storage compliance');
      await _deleteViaMediaStore(videoPath);

      // Also try to delete associated thumbnail if it exists
      final thumbnailPath = await _getThumbnailPath(videoPath);
      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        final thumbnailExists = await thumbnailFile.exists();
        debugPrint(
            'VideoLocalDataSource: Thumbnail exists: $thumbnailExists at $thumbnailPath');
        if (thumbnailExists) {
          try {
            await thumbnailFile.delete();
            debugPrint('VideoLocalDataSource: Thumbnail deleted successfully');
          } catch (e) {
            debugPrint('VideoLocalDataSource: Failed to delete thumbnail: $e');
            // Don't fail the whole operation if thumbnail deletion fails
          }
        }
      }

      debugPrint(
          'VideoLocalDataSource: Successfully completed video deletion: $videoPath');
    } catch (e) {
      debugPrint('VideoLocalDataSource: Error deleting video: $e');
      rethrow;
    }
  }

  Future<void> _deleteViaMediaStore(String videoPath) async {
    try {
      debugPrint(
          'VideoLocalDataSource: Starting MediaStore deletion for: $videoPath');

      // First, ensure we have the necessary permissions using permission service
      final permissionService = PermissionService.instance;
      final hasPermission = await permissionService.requestStoragePermissions();

      if (!hasPermission) {
        final permissionState = await permissionService.getPermissionState();
        final message =
            permissionService.getPermissionStatusMessage(permissionState);
        throw Exception(
            '$message Please grant storage access in app settings to delete videos.');
      }

      debugPrint(
          'VideoLocalDataSource: Storage permissions granted successfully');

      debugPrint(
          'VideoLocalDataSource: Permission granted, searching for asset...');

      // Find the asset by path using photo_manager
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: true,
      );

      AssetEntity? targetAsset;
      int totalAssetsChecked = 0;

      for (final path in paths) {
        debugPrint('VideoLocalDataSource: Checking path: ${path.name}');
        final assetCount = await path.assetCountAsync;
        debugPrint('VideoLocalDataSource: Path has $assetCount assets');

        final List<AssetEntity> assets = await path.getAssetListRange(
          start: 0,
          end: assetCount,
        );

        for (final asset in assets) {
          totalAssetsChecked++;
          final file = await asset.file;
          if (file != null && file.path == videoPath) {
            targetAsset = asset;
            debugPrint(
                'VideoLocalDataSource: Found matching asset: ${asset.id}');
            break;
          }
        }
        if (targetAsset != null) break;
      }

      debugPrint(
          'VideoLocalDataSource: Checked $totalAssetsChecked total assets');

      if (targetAsset != null) {
        debugPrint(
            'VideoLocalDataSource: Found asset for MediaStore deletion: ${targetAsset.id}');

        // Use photo_manager to delete the asset (this handles MediaStore properly)
        final List<String> result =
            await PhotoManager.editor.deleteWithIds([targetAsset.id]);

        if (result.isNotEmpty && result.contains(targetAsset.id)) {
          debugPrint(
              'VideoLocalDataSource: Video deleted successfully via MediaStore');
        } else {
          throw Exception(
              'MediaStore deletion failed - video may be protected or in use');
        }
      } else {
        // If we can't find the asset in MediaStore, it might be a file that's not indexed
        // Try direct file deletion as a last resort
        debugPrint(
            'VideoLocalDataSource: Asset not found in MediaStore, trying direct deletion...');
        final file = File(videoPath);
        if (await file.exists()) {
          try {
            await file.delete();
            debugPrint('VideoLocalDataSource: Direct deletion successful');
          } catch (e) {
            throw Exception(
                'Cannot delete this video file. It may be in a protected location or currently in use. Error: ${e.toString()}');
          }
        } else {
          throw Exception('Video file not found at path: $videoPath');
        }
      }
    } catch (e) {
      debugPrint('VideoLocalDataSource: MediaStore deletion failed: $e');
      rethrow;
    }
  }

  Future<String?> _getThumbnailPath(String videoPath) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final videoName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath =
          path.join(cacheDir.path, '${videoName}_thumbnail.jpg');
      return thumbnailPath;
    } catch (e) {
      return null;
    }
  }
}
