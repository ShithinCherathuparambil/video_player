import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/core/error/exceptions.dart';
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
  final _supportedExtensions = [
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.3gp'
  ];

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
      print('Requesting photo manager permission...');
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      print('Permission state: ${ps.hasAccess}');

      if (!ps.hasAccess) {
        throw PermissionDeniedException(
            'Photo library permission not granted. Please grant permission in settings.');
      }

      print('Getting asset path list...');
      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );

      print('Found ${paths.length} asset paths');
      if (paths.isEmpty) {
        print('No video albums found');
        return videos; // No video albums found
      }

      final AssetPathEntity recentPath = paths.first;
      print('Using path: ${recentPath.name}');

      final List<AssetEntity> entities = await recentPath.getAssetListPaged(
        page: 0,
        size: 100, // Increased to get more videos
      );

      print('Found ${entities.length} video entities');

      for (int i = 0; i < entities.length; i++) {
        final entity = entities[i];
        print('Processing entity $i: ${entity.title} (type: ${entity.type})');

        if (entity.type == AssetType.video) {
          print('Getting file for video: ${entity.title}');
          final file = await entity.file;
          if (file != null) {
            print('File path: ${file.path}');

            // Only generate thumbnail for the first 10 videos to improve loading speed
            String? thumbnailPath;
            Duration? duration;
            if (videos.length < 10) {
              print('Generating thumbnail and duration for: ${entity.title}');
              // Generate thumbnail and duration in parallel for better performance
              final results = await Future.wait([
                _generateThumbnail(file.path),
                _extractVideoDuration(file.path),
              ]);
              thumbnailPath = results[0] as String?;
              duration = results[1] as Duration?;
            }

            final videoFile = VideoFile(
              path: file.path,
              name: entity.title ?? path.basename(file.path),
              thumbnailPath: thumbnailPath,
              duration: duration,
              fileSize: await file.length(),
              dateAdded: entity.createDateTime,
            );

            videos.add(videoFile);
            print('Added video: ${videoFile.name}');
          } else {
            print('Failed to get file for entity: ${entity.title}');
          }
        }
      }

      print('Successfully loaded ${videos.length} videos');
    } catch (e) {
      print('Error getting platform videos: $e');
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
      print('Error getting videos: $e');
    }
    return videos;
  }

  bool _isVideoFile(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return _supportedExtensions.contains('.' + extension);
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
      print('Error generating thumbnail: $e');
      return null;
    }
  }

  Future<Duration?> _extractVideoDuration(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));

      // Add timeout to prevent hanging on problematic videos
      final duration = await controller.initialize().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          controller.dispose();
          return Duration.zero;
        },
      );

      final videoDuration = controller.value.duration;
      await controller.dispose();
      return videoDuration;
    } catch (e) {
      print('Error extracting video duration: $e');
      return null;
    }
  }

  @override
  Future<void> requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      print('Requesting photo manager permissions...');
      try {
        final PermissionState ps = await PhotoManager.requestPermissionExtend();
        print('Permission result: ${ps.hasAccess}');
        if (!ps.hasAccess) {
          throw PermissionDeniedException(
              'Photo library permission not granted.');
        }
        print('Permission granted successfully');
      } catch (e) {
        print('Error requesting permissions: $e');
        rethrow;
      }
    }
  }

  // Debug method to check permission status
  Future<bool> checkPermissionStatus() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final PermissionState ps = await PhotoManager.requestPermissionExtend();
        print('Current permission status: ${ps.hasAccess}');
        return ps.hasAccess;
      } catch (e) {
        print('Error checking permission status: $e');
        return false;
      }
    }
    return true; // For non-mobile platforms
  }
}
