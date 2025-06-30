import 'dart:io';
import 'package:path/path.dart' as path;

/// Security utility for validating file paths and preventing path traversal attacks
class PathValidator {
  // Allowed video file extensions
  static const List<String> _allowedVideoExtensions = [
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

  // Dangerous path patterns that should be blocked
  static const List<String> _dangerousPatterns = [
    '..',
    '~',
    '/etc/',
    '/bin/',
    '/usr/',
    '/var/',
    '/tmp/',
    '/root/',
    '/home/',
    '\\windows\\',
    '\\system32\\',
    '\\program files\\',
  ];

  /// Validates if a file path is safe and points to a valid video file
  static bool isValidVideoPath(String filePath) {
    if (filePath.isEmpty) return false;

    // Normalize the path to prevent bypass attempts
    final normalizedPath = path.normalize(filePath).toLowerCase();

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (normalizedPath.contains(pattern.toLowerCase())) {
        return false;
      }
    }

    // Check if it's a valid video file extension
    return isValidVideoExtension(filePath);
  }

  /// Validates if a file has a valid video extension
  static bool isValidVideoExtension(String filePath) {
    if (filePath.isEmpty) return false;

    final extension = path.extension(filePath).toLowerCase();
    return _allowedVideoExtensions.contains(extension);
  }

  /// Sanitizes a search query to prevent injection attacks
  static String sanitizeSearchQuery(String query) {
    if (query.isEmpty) return '';

    // Remove potentially dangerous characters
    final sanitized = query
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('\\', '')
        .replaceAll('/', '')
        .replaceAll(';', '')
        .replaceAll('&', '')
        .replaceAll('|', '')
        .replaceAll('`', '')
        .replaceAll('\$', '')
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    // Limit length to prevent DoS
    return sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;
  }

  /// Validates if a file exists and is accessible
  static Future<bool> isFileAccessible(String filePath) async {
    try {
      if (!isValidVideoPath(filePath)) return false;

      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Securely extracts filename from path
  static String getSecureFileName(String filePath) {
    if (!isValidVideoPath(filePath)) return 'Unknown';

    try {
      return path.basename(filePath);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Validates thumbnail path for security
  static bool isValidThumbnailPath(String? thumbnailPath) {
    if (thumbnailPath == null || thumbnailPath.isEmpty) return true;

    final normalizedPath = path.normalize(thumbnailPath).toLowerCase();

    // Check for dangerous patterns
    for (final pattern in _dangerousPatterns) {
      if (normalizedPath.contains(pattern.toLowerCase())) {
        return false;
      }
    }

    // Should be in temp directory or app directory
    return normalizedPath.contains('/tmp/') ||
        normalizedPath.contains('/cache/') ||
        normalizedPath.contains('\\temp\\') ||
        normalizedPath.contains('\\cache\\');
  }
}
