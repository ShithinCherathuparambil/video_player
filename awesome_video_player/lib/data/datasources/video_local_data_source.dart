import 'dart:async';
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
  Future<List<VideoFile>> getVideos({int page = 0, int pageSize = 20});
  Future<void> requestPermissions();
  Future<void> deleteVideo(String videoPath);
  Future<int> getTotalVideoCount();
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  final Directory? _directory;
  final Map<String, Uint8List> _thumbnailCache = {};
  final Map<String, Duration?> _durationCache = {};
  String? _currentSearchQuery;
  List<VideoFile>? _searchResults;

  VideoLocalDataSourceImpl({Directory? directory}) : _directory = directory;

  @override
  Future<List<VideoFile>> getVideos({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
    bool keepCurrentSearch = true,
  }) async {
    try {
      // If we have a search query, update the search state
      if (searchQuery != null && searchQuery.isNotEmpty) {
        _currentSearchQuery = searchQuery;
        _searchResults = null; // Clear cache for new search
      }

      // If we want to keep current search and have a previous search query
      if (keepCurrentSearch &&
          _currentSearchQuery != null &&
          _currentSearchQuery!.isNotEmpty) {
        // Use cached results if available
        if (_searchResults != null) {
          final start = page * pageSize;
          final end = start + pageSize;
          return _searchResults!.sublist(
            start,
            end.clamp(0, _searchResults!.length),
          );
        }

        // Get all videos and filter
        final allVideos = await _getAllVideos();
        _searchResults = allVideos.where((video) {
          final searchText = _currentSearchQuery!.toLowerCase();
          return video.name.toLowerCase().contains(searchText) ||
              path
                  .basenameWithoutExtension(video.path)
                  .toLowerCase()
                  .contains(searchText);
        }).toList();

        final start = page * pageSize;
        final end = start + pageSize;
        return _searchResults!.sublist(
          start,
          end.clamp(0, _searchResults!.length),
        );
      }

      // No search active, clear search state
      _currentSearchQuery = null;
      _searchResults = null;

      if (Platform.isAndroid || Platform.isIOS) {
        return await _getPlatformVideos(page: page, pageSize: pageSize);
      } else {
        return await _getLocalVideos(page: page, pageSize: pageSize);
      }
    } catch (e) {
      debugPrint('Error getting videos: $e');
      throw CacheException();
    }
  }

  Future<List<VideoFile>> _getAllVideos() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) {
        throw PermissionDeniedException(
            'Photo library permission not granted. Please grant permission in settings.');
      }

      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );

      if (paths.isEmpty) return [];

      final recentPath = paths.first;
      final assetCount = await recentPath.assetCountAsync;
      final List<VideoFile> allVideos = [];

      // Get all videos in batches to avoid memory issues
      const batchSize = 50;
      for (int i = 0; i < assetCount; i += batchSize) {
        final videos = await _getPlatformVideos(
          page: i ~/ batchSize,
          pageSize: batchSize.clamp(0, assetCount - i),
        );
        allVideos.addAll(videos);
      }
      return allVideos;
    } else {
      return await _getLocalVideos(
          page: 0, pageSize: 1000); // Adjust page size as needed
    }
  }

  Future<List<VideoFile>> _getPlatformVideos(
      {int page = 0, int pageSize = 20}) async {
    final List<VideoFile> videos = [];
    final List<String> processedPaths = [];

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
        debugPrint('No video albums found.');
        return videos;
      }

      final AssetPathEntity recentPath = paths.first;
      final List<AssetEntity> entities = await recentPath.getAssetListPaged(
        page: page,
        size: pageSize,
      );

      debugPrint('Found ${entities.length} video assets');

      for (final entity in entities) {
        try {
          if (entity.type != AssetType.video) continue;

          final file = await entity.file;
          if (file == null) continue;

          if (processedPaths.contains(file.path)) continue;

          final isValid =
              Platform.isIOS || PathValidator.isValidVideoPath(file.path);
          if (!isValid) continue;

          String? thumbnailPath;
          Uint8List? thumbnailBytes;
          Duration? duration;

          if (videos.length < 10) {
            if (Platform.isIOS) {
              thumbnailBytes = await entity
                  .thumbnailDataWithSize(const ThumbnailSize(120, 120));
              duration = await _getDuration(file.path);
            } else {
              thumbnailPath = await _generateThumbnail(file.path);
              duration = await _getDuration(file.path);
            }

            if (thumbnailPath != null &&
                !PathValidator.isValidThumbnailPath(thumbnailPath)) {
              thumbnailPath = null;
            }
          }

          final videoFile = VideoFile(
            path: file.path,
            name: Platform.isIOS &&
                    entity.title != null &&
                    entity.title!.isNotEmpty
                ? entity.title!
                : path.basename(file.path),
            thumbnailPath: thumbnailPath,
            thumbnailBytes: thumbnailBytes,
            duration: duration,
            fileSize: await file.length(),
            dateAdded: entity.createDateTime,
          );

          videos.add(videoFile);
          processedPaths.add(file.path);
        } catch (e) {
          debugPrint('Error processing video asset: $e');
        }
      }

      return videos;
    } catch (e) {
      debugPrint('Error in _getPlatformVideos: $e');
      if (e is PermissionDeniedException) rethrow;
      throw CacheException();
    }
  }

  Future<Duration?> _getDuration(String videoPath) async {
    if (_durationCache.containsKey(videoPath)) {
      return _durationCache[videoPath];
    }

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          controller?.dispose();
          throw TimeoutException('Video initialization timed out');
        },
      );

      final duration = controller.value.duration;
      _durationCache[videoPath] = duration;
      return duration;
    } catch (e) {
      debugPrint('Error getting video duration: $e');
      _durationCache[videoPath] = null;
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    try {
      final thumbnailDir = await getTemporaryDirectory();
      final videoHash = path.basenameWithoutExtension(videoPath).hashCode;
      final thumbnailPath = '${thumbnailDir.path}/thumb_$videoHash.jpg';

      final existingThumb = File(thumbnailPath);
      if (await existingThumb.exists()) {
        final fileStats = await existingThumb.stat();
        if (DateTime.now().difference(fileStats.modified) <
            const Duration(hours: 24)) {
          return thumbnailPath;
        }
        await existingThumb.delete();
      }

      await _cleanupOldThumbnails();

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 120,
        quality: 30,
        timeMs: 1000,
      );

      return thumbnail;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  Future<void> _cleanupOldThumbnails() async {
    try {
      final thumbnailDir = await getTemporaryDirectory();
      final entities = await thumbnailDir.list().toList();
      final now = DateTime.now();

      for (var entity in entities) {
        if (entity is File && entity.path.contains('thumb_')) {
          final fileStats = await entity.stat();
          if (now.difference(fileStats.modified) > const Duration(hours: 24)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up thumbnails: $e');
    }
  }

  Future<List<VideoFile>> _getLocalVideos(
      {int page = 0, int pageSize = 20}) async {
    final List<VideoFile> videos = [];
    final directory = _directory ?? await getApplicationDocumentsDirectory();

    try {
      final List<FileSystemEntity> files = directory.listSync(recursive: true);
      for (var file in files) {
        if (file is File && PathValidator.isValidVideoPath(file.path)) {
          final thumbnailPath = await _generateThumbnail(file.path);
          final duration = await _getDuration(file.path);

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
      debugPrint('Error getting local videos: $e');
    }

    final start = page * pageSize;
    final end = start + pageSize;
    return videos.sublist(start, end.clamp(0, videos.length));
  }

  @override
  Future<void> deleteVideo(String videoPath) async {
    try {
      debugPrint('Starting deletion of video: $videoPath');

      if (!PathValidator.isValidVideoPath(videoPath)) {
        throw Exception('Invalid video path');
      }

      if (Platform.isAndroid || Platform.isIOS) {
        await _deleteViaMediaStore(videoPath);
      } else {
        final file = File(videoPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _thumbnailCache.remove(videoPath);
      _durationCache.remove(videoPath);
    } catch (e) {
      debugPrint('Error deleting video: $e');
      rethrow;
    }
  }

  Future<void> _deleteViaMediaStore(String videoPath) async {
    try {
      final hasPermission =
          await PermissionService.instance.requestStoragePermissions();
      if (!hasPermission) {
        final state = await PermissionService.instance.getPermissionState();
        final message =
            PermissionService.instance.getPermissionStatusMessage(state);
        throw Exception(
            '$message Please grant storage access in app settings.');
      }

      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: true,
      );

      for (final path in paths) {
        final assets = await path.getAssetListRange(
          start: 0,
          end: await path.assetCountAsync,
        );

        for (final asset in assets) {
          final file = await asset.file;
          if (file?.path == videoPath) {
            final result = await PhotoManager.editor.deleteWithIds([asset.id]);
            if (result.contains(asset.id)) {
              return;
            }
            throw Exception(
                'MediaStore deletion failed - video may be protected or in use');
          }
        }
      }

      // Fallback to direct file deletion
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
      } else {
        throw Exception('Video file not found: $videoPath');
      }
    } catch (e) {
      debugPrint('MediaStore deletion failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) {
        throw PermissionDeniedException(
            'Photo library permission not granted.');
      }
    }
  }

  @override
  Future<int> getTotalVideoCount() async {
    try {
      final ps = await PhotoManager.requestPermissionExtend();
      if (!ps.hasAccess) {
        throw PermissionDeniedException(
            'Photo library permission not granted. Please grant permission in settings.');
      }

      final paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );

      if (paths.isEmpty) return 0;

      final recentPath = paths.first;
      return await recentPath.assetCountAsync;
    } catch (e) {
      debugPrint('Error getting video count: $e');
      return 0;
    }
  }
}
