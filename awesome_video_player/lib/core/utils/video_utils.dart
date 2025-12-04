import 'dart:io';

/// Utility functions for video file operations
class VideoUtils {
  /// Supported video formats
  static const List<String> supportedFormats = [
    'mp4',
    'mkv',
    'avi',
    'flv',
    'ts',
    'mov',
    'webm',
    'm4v',
    '3gp',
    'wmv',
    'mpg',
    'mpeg',
    'rm',
    'rmvb',
    'vob',
    'asf',
    'divx',
    'xvid',
  ];

  /// Check if file is a supported video format
  static bool isVideoFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return supportedFormats.contains(extension);
  }

  /// Get file extension
  static String getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  /// Format file size to human-readable string
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format duration to human-readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Get video file size
  static Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  /// Check if file exists
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get file name without extension
  static String getFileNameWithoutExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex > 0) {
      return fileName.substring(0, lastDotIndex);
    }
    return fileName;
  }

  /// Get directory path
  static String getDirectoryPath(String filePath) {
    final lastSlashIndex = filePath.lastIndexOf('/');
    if (lastSlashIndex > 0) {
      return filePath.substring(0, lastSlashIndex);
    }
    return '/';
  }
}

