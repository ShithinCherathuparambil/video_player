import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Smart folder types
enum SmartFolderType {
  movies,
  series,
  downloads,
  camera,
  custom,
}

/// Smart folder information
class SmartFolder {
  final String name;
  final String path;
  final SmartFolderType type;
  final List<String> videoPaths;

  const SmartFolder({
    required this.name,
    required this.path,
    required this.type,
    this.videoPaths = const [],
  });
}

/// Service for managing smart folders
class SmartFolderService {
  static const String _customFoldersKey = 'smart_folders_custom';
  /// Auto-detect smart folders
  Future<List<SmartFolder>> detectSmartFolders() async {
    final folders = <SmartFolder>[];

    try {
      // Movies folder
      final moviesPath = await _getMoviesPath();
      if (moviesPath != null && await Directory(moviesPath).exists()) {
        final videos = await _scanForVideos(moviesPath);
        folders.add(SmartFolder(
          name: 'Movies',
          path: moviesPath,
          type: SmartFolderType.movies,
          videoPaths: videos,
        ));
      }

      // Downloads folder
      final downloadsPath = await _getDownloadsPath();
      if (downloadsPath != null && await Directory(downloadsPath).exists()) {
        final videos = await _scanForVideos(downloadsPath);
        folders.add(SmartFolder(
          name: 'Downloads',
          path: downloadsPath,
          type: SmartFolderType.downloads,
          videoPaths: videos,
        ));
      }

      // Camera folder
      final cameraPath = await _getCameraPath();
      if (cameraPath != null && await Directory(cameraPath).exists()) {
        final videos = await _scanForVideos(cameraPath);
        folders.add(SmartFolder(
          name: 'Camera',
          path: cameraPath,
          type: SmartFolderType.camera,
          videoPaths: videos,
        ));
      }
    } catch (e) {
      debugPrint('Error detecting smart folders: $e');
    }

    return folders;
  }

  /// Get movies folder path
  Future<String?> _getMoviesPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final moviesPath = '${directory.path}/Movies';
      return moviesPath;
    } catch (e) {
      debugPrint('Error getting movies path: $e');
      return null;
    }
  }

  /// Get downloads folder path
  Future<String?> _getDownloadsPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsPath = '${directory.path}/Downloads';
      return downloadsPath;
    } catch (e) {
      debugPrint('Error getting downloads path: $e');
      return null;
    }
  }

  /// Get camera folder path
  Future<String?> _getCameraPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cameraPath = '${directory.path}/DCIM/Camera';
      return cameraPath;
    } catch (e) {
      debugPrint('Error getting camera path: $e');
      return null;
    }
  }

  /// Scan directory for video files
  Future<List<String>> _scanForVideos(String directoryPath) async {
    final videos = <String>[];
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return videos;
      }

      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final extension = entity.path.split('.').last.toLowerCase();
          if (_isVideoFile(extension)) {
            videos.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning for videos: $e');
    }
    return videos;
  }

  /// Check if file extension is a video format
  bool _isVideoFile(String extension) {
    const videoExtensions = [
      'mp4',
      'mkv',
      'avi',
      'flv',
      'ts',
      'mov',
      'webm',
      'm4v',
      '3gp',
    ];
    return videoExtensions.contains(extension);
  }

  /// Add custom folder
  Future<void> addCustomFolder(String name, String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customFolders = await getCustomFolders();
      
      // Check if folder already exists
      final exists = customFolders.any((folder) => folder.path == path);
      if (exists) {
        debugPrint('Custom folder already exists: $path');
        return;
      }
      
      // Add new folder
      final newFolder = SmartFolder(
        name: name,
        path: path,
        type: SmartFolderType.custom,
        videoPaths: await _scanForVideos(path),
      );
      
      customFolders.add(newFolder);
      
      // Save to preferences
      final foldersJson = customFolders.map((folder) => {
        'name': folder.name,
        'path': folder.path,
        'type': folder.type.toString(),
        'videoPaths': folder.videoPaths,
      }).toList();
      
      await prefs.setString(_customFoldersKey, jsonEncode(foldersJson));
      debugPrint('Custom folder saved: $name at $path');
    } catch (e) {
      debugPrint('Error saving custom folder: $e');
    }
  }

  /// Get custom folders
  Future<List<SmartFolder>> getCustomFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersJson = prefs.getString(_customFoldersKey);
      
      if (foldersJson == null) {
        return [];
      }
      
      final decoded = jsonDecode(foldersJson) as List<dynamic>;
      return decoded.map((folderData) {
        return SmartFolder(
          name: folderData['name'] as String,
          path: folderData['path'] as String,
          type: SmartFolderType.custom,
          videoPaths: List<String>.from(folderData['videoPaths'] as List),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading custom folders: $e');
      return [];
    }
  }

  /// Remove custom folder
  Future<void> removeCustomFolder(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customFolders = await getCustomFolders();
      
      customFolders.removeWhere((folder) => folder.path == path);
      
      // Save updated list
      final foldersJson = customFolders.map((folder) => {
        'name': folder.name,
        'path': folder.path,
        'type': folder.type.toString(),
        'videoPaths': folder.videoPaths,
      }).toList();
      
      await prefs.setString(_customFoldersKey, jsonEncode(foldersJson));
      debugPrint('Custom folder removed: $path');
    } catch (e) {
      debugPrint('Error removing custom folder: $e');
    }
  }
}

