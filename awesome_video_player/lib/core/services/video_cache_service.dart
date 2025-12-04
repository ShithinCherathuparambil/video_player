import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for caching video thumbnails and metadata to optimize loading
class VideoCacheService {
  static VideoCacheService? _instance;
  static VideoCacheService get instance {
    _instance ??= VideoCacheService._();
    return _instance!;
  }

  VideoCacheService._();

  // In-memory caches
  final Map<String, Uint8List> _thumbnailMemoryCache = {};
  final Map<String, Duration?> _durationCache = {};
  final Map<String, int?> _fileSizeCache = {};
  
  // Cache size limits
  static const int _maxThumbnailCacheSize = 100; // Max thumbnails in memory
  static const int _maxDurationCacheSize = 500; // Max durations in memory
  static const int _maxFileSizeCacheSize = 500; // Max file sizes in memory

  Directory? _cacheDirectory;

  /// Initialize cache directory
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory(path.join(appDir.path, 'video_cache'));
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
    } catch (e) {
      debugPrint('Error initializing cache directory: $e');
    }
  }

  /// Get thumbnail from cache (memory first, then disk)
  Future<Uint8List?> getThumbnail(String videoPath) async {
    // Check memory cache first
    if (_thumbnailMemoryCache.containsKey(videoPath)) {
      return _thumbnailMemoryCache[videoPath];
    }

    // Check disk cache
    if (_cacheDirectory != null) {
      try {
        final cacheFile = File(path.join(
          _cacheDirectory!.path,
          '${videoPath.hashCode}.thumb',
        ));
        if (await cacheFile.exists()) {
          final bytes = await cacheFile.readAsBytes();
          // Add to memory cache
          _addToThumbnailCache(videoPath, bytes);
          return bytes;
        }
      } catch (e) {
        debugPrint('Error reading thumbnail from disk cache: $e');
      }
    }

    return null;
  }

  /// Save thumbnail to cache (memory and disk)
  Future<void> saveThumbnail(String videoPath, Uint8List thumbnailBytes) async {
    // Add to memory cache
    _addToThumbnailCache(videoPath, thumbnailBytes);

    // Save to disk cache
    if (_cacheDirectory != null) {
      try {
        final cacheFile = File(path.join(
          _cacheDirectory!.path,
          '${videoPath.hashCode}.thumb',
        ));
        await cacheFile.writeAsBytes(thumbnailBytes);
      } catch (e) {
        debugPrint('Error saving thumbnail to disk cache: $e');
      }
    }
  }

  /// Add thumbnail to memory cache with size limit
  void _addToThumbnailCache(String videoPath, Uint8List bytes) {
    // Remove oldest entries if cache is full
    if (_thumbnailMemoryCache.length >= _maxThumbnailCacheSize) {
      final firstKey = _thumbnailMemoryCache.keys.first;
      _thumbnailMemoryCache.remove(firstKey);
    }
    _thumbnailMemoryCache[videoPath] = bytes;
  }

  /// Get duration from cache
  Duration? getDuration(String videoPath) {
    return _durationCache[videoPath];
  }

  /// Save duration to cache
  void saveDuration(String videoPath, Duration? duration) {
    // Remove oldest entries if cache is full
    if (_durationCache.length >= _maxDurationCacheSize) {
      final firstKey = _durationCache.keys.first;
      _durationCache.remove(firstKey);
    }
    _durationCache[videoPath] = duration;
  }

  /// Get file size from cache
  int? getFileSize(String videoPath) {
    return _fileSizeCache[videoPath];
  }

  /// Save file size to cache
  void saveFileSize(String videoPath, int? fileSize) {
    // Remove oldest entries if cache is full
    if (_fileSizeCache.length >= _maxFileSizeCacheSize) {
      final firstKey = _fileSizeCache.keys.first;
      _fileSizeCache.remove(firstKey);
    }
    _fileSizeCache[videoPath] = fileSize;
  }

  /// Clear all caches
  Future<void> clearAll() async {
    _thumbnailMemoryCache.clear();
    _durationCache.clear();
    _fileSizeCache.clear();

    // Clear disk cache
    if (_cacheDirectory != null) {
      try {
        if (await _cacheDirectory!.exists()) {
          await for (final entity in _cacheDirectory!.list()) {
            if (entity is File) {
              await entity.delete();
            }
          }
        }
      } catch (e) {
        debugPrint('Error clearing disk cache: $e');
      }
    }
  }

  /// Clear cache for a specific video
  Future<void> clearVideoCache(String videoPath) async {
    _thumbnailMemoryCache.remove(videoPath);
    _durationCache.remove(videoPath);
    _fileSizeCache.remove(videoPath);

    // Clear disk cache
    if (_cacheDirectory != null) {
      try {
        final cacheFile = File(path.join(
          _cacheDirectory!.path,
          '${videoPath.hashCode}.thumb',
        ));
        if (await cacheFile.exists()) {
          await cacheFile.delete();
        }
      } catch (e) {
        debugPrint('Error clearing video disk cache: $e');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    int diskCacheSize = 0;
    if (_cacheDirectory != null && _cacheDirectory!.existsSync()) {
      try {
        final files = _cacheDirectory!.listSync();
        for (final file in files) {
          if (file is File) {
            diskCacheSize += file.lengthSync();
          }
        }
      } catch (e) {
        debugPrint('Error calculating disk cache size: $e');
      }
    }

    return {
      'memoryThumbnails': _thumbnailMemoryCache.length,
      'memoryDurations': _durationCache.length,
      'memoryFileSizes': _fileSizeCache.length,
      'diskCacheSizeBytes': diskCacheSize,
      'diskCacheSizeMB': (diskCacheSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// Preload thumbnails for visible videos (for smooth scrolling)
  Future<void> preloadThumbnails(List<String> videoPaths) async {
    // Limit concurrent preloads
    const maxConcurrent = 5;
    final futures = <Future>[];

    for (final videoPath in videoPaths) {
      // Skip if already in memory cache
      if (_thumbnailMemoryCache.containsKey(videoPath)) {
        continue;
      }

      // Load from disk cache
      futures.add(getThumbnail(videoPath));

      // Limit concurrent operations
      if (futures.length >= maxConcurrent) {
        await Future.wait(futures);
        futures.clear();
      }
    }

    // Wait for remaining operations
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
}

