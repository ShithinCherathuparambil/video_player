import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

abstract class VideoLocalDataSource {
  /// Fetches list of raw video file paths.
  ///
  /// Throws [PermissionDeniedException] if storage/video permission is not granted.
  /// Throws [FileSystemException] or other platform exceptions for I/O errors.
  Future<List<String>> getVideoPaths();
}

// Custom exception for permission issues
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}

class VideoLocalDataSourceImpl implements VideoLocalDataSource {
  // Re-using the core logic from the previous VideoListPage.
  // This logic has known limitations regarding full access to public directories on Android due to scoped storage.
  // A production app would need a more robust solution (e.g., MediaStore API via platform channels).

  @override
  Future<List<String>> getVideoPaths() async {
    PermissionStatus videoPermissionStatus;

    if (Platform.isAndroid) {
      // Requesting both, system usually handles which one is appropriate or if both are needed.
      // More granular SDK checks could be added if specific behavior is required.
      // For Android 13+, Permission.videos is preferred.
      // For older, Permission.storage. Permission_handler might handle some of this.
      var videosStatus = await Permission.videos.request();
      if (videosStatus.isGranted) {
        videoPermissionStatus = videosStatus;
      } else {
        // Fallback or if videos permission is not enough/applicable
        videoPermissionStatus = await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      videoPermissionStatus = await Permission.photos.request(); // For videos in photo library
    } else {
      videoPermissionStatus = await Permission.storage.request(); // Generic fallback
    }

    if (!videoPermissionStatus.isGranted) {
      throw PermissionDeniedException('Storage/video permission was not granted. Status: $videoPermissionStatus');
    }

    final List<Directory> mediaDirsToScan = [];
    if (Platform.isAndroid) {
      List<Directory>? externalStorageDirs = await getExternalStorageDirectories();
      if (externalStorageDirs != null) {
        mediaDirsToScan.addAll(externalStorageDirs);
      }
      // Attempting to add common public directories.
      // Note: Direct access to these paths is unreliable on modern Android due to scoped storage.
      // This part is more illustrative and would need platform-specific APIs (MediaStore/SAF) for robust access.
      // final List<Directory> commonPublicDirs = [
      //   Directory('/storage/emulated/0/Movies'),
      //   Directory('/storage/emulated/0/DCIM'),
      //   Directory('/storage/emulated/0/Download'),
      // ];
      // for (var dir in commonPublicDirs) {
      //   if (await dir.exists()) { // This check itself might be problematic for restricted dirs
      //     mediaDirsToScan.add(dir);
      //   }
      // }
    } else if (Platform.isIOS) {
      // On iOS, videos are typically accessed via the photo library (using Permission.photos).
      // Specific plugins like photo_manager or image_picker would then be used to browse this library.
      // path_provider gives app-specific directories, not the general media library.
      // For this data source, we'll assume that if permission is granted,
      // a subsequent step (perhaps in a use case or a more specialized data source)
      // would use a dedicated plugin to pick files from the photo library.
      // So, for iOS, this raw path fetching might return an empty list unless files are in app's own dirs.
      Directory appDocsDir = await getApplicationDocumentsDirectory();
      mediaDirsToScan.add(appDocsDir); // Example: scan app's own documents directory
    }

    if (mediaDirsToScan.isEmpty) {
      // Could indicate no external storage or specific issue on platform.
      return [];
    }

    List<String> videoFilePaths = [];
    for (var dir in mediaDirsToScan) {
      if (await dir.exists()) {
        try {
          final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);
          for (var entity in entities) {
            if (entity is File) {
              String path = entity.path.toLowerCase();
              if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || path.endsWith('.mkv')) {
                videoFilePaths.add(entity.path);
              }
            }
          }
        } catch (e) {
          // Log error or handle specific directory access errors
          print('Error listing files in directory ${dir.path}: $e');
          // Depending on policy, might re-throw or just skip this directory
        }
      }
    }
    return videoFilePaths;
  }
}
