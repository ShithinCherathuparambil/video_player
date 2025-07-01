import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/entities/app_settings.dart';

/// Builder pattern for creating test data with fluent API
class VideoFileBuilder {
  String _path = '/test/video.mp4';
  String _name = 'Test Video';
  String? _thumbnailPath = '/test/thumbnail.jpg';
  Duration? _duration = const Duration(minutes: 5);
  int? _fileSize = 1024000;
  DateTime? _dateAdded;
  Duration? _lastPlayedPosition = Duration.zero;
  DateTime? _lastPlayedAt;
  VideoStatus _status = VideoStatus.new_;
  bool _isFavorite = false;

  VideoFileBuilder() {
    _dateAdded = DateTime.now();
  }

  VideoFileBuilder withPath(String path) {
    _path = path;
    return this;
  }

  VideoFileBuilder withName(String name) {
    _name = name;
    return this;
  }

  VideoFileBuilder withThumbnailPath(String? thumbnailPath) {
    _thumbnailPath = thumbnailPath;
    return this;
  }

  VideoFileBuilder withDuration(Duration? duration) {
    _duration = duration;
    return this;
  }

  VideoFileBuilder withFileSize(int? fileSize) {
    _fileSize = fileSize;
    return this;
  }

  VideoFileBuilder withDateAdded(DateTime? dateAdded) {
    _dateAdded = dateAdded;
    return this;
  }

  VideoFileBuilder withLastPlayedPosition(Duration? position) {
    _lastPlayedPosition = position;
    return this;
  }

  VideoFileBuilder withLastPlayedAt(DateTime? lastPlayedAt) {
    _lastPlayedAt = lastPlayedAt;
    return this;
  }

  VideoFileBuilder withStatus(VideoStatus status) {
    _status = status;
    return this;
  }

  VideoFileBuilder asFavorite() {
    _isFavorite = true;
    return this;
  }

  VideoFileBuilder asNotFavorite() {
    _isFavorite = false;
    return this;
  }

  VideoFileBuilder asWatched() {
    _status = VideoStatus.watched;
    _lastPlayedAt = DateTime.now();
    _lastPlayedPosition = _duration;
    return this;
  }

  VideoFileBuilder asPartiallyWatched() {
    _status = VideoStatus.watching;
    _lastPlayedAt = DateTime.now();
    _lastPlayedPosition = _duration != null
        ? Duration(milliseconds: (_duration!.inMilliseconds * 0.5).round())
        : null;
    return this;
  }

  VideoFile build() {
    return VideoFile(
      path: _path,
      name: _name,
      thumbnailPath: _thumbnailPath,
      duration: _duration,
      fileSize: _fileSize,
      dateAdded: _dateAdded,
      lastPlayedPosition: _lastPlayedPosition,
      lastPlayedAt: _lastPlayedAt,
      status: _status,
      isFavorite: _isFavorite,
    );
  }
}

/// Builder pattern for creating app settings test data
class AppSettingsBuilder {
  ThemeMode _themeMode = ThemeMode.system;
  bool? _isGridView = true;
  bool _subtitlesEnabled = false;
  String _videoDecoder = 'auto';
  bool _hardwareAcceleration = true;

  AppSettingsBuilder withThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    return this;
  }

  AppSettingsBuilder withGridView(bool isGridView) {
    _isGridView = isGridView;
    return this;
  }

  AppSettingsBuilder withSubtitlesEnabled(bool enabled) {
    _subtitlesEnabled = enabled;
    return this;
  }

  AppSettingsBuilder withVideoDecoder(String decoder) {
    _videoDecoder = decoder;
    return this;
  }

  AppSettingsBuilder withHardwareAcceleration(bool enabled) {
    _hardwareAcceleration = enabled;
    return this;
  }

  AppSettingsBuilder asLightTheme() {
    _themeMode = ThemeMode.light;
    return this;
  }

  AppSettingsBuilder asDarkTheme() {
    _themeMode = ThemeMode.dark;
    return this;
  }

  AppSettingsBuilder asSystemTheme() {
    _themeMode = ThemeMode.system;
    return this;
  }

  AppSettingsBuilder withListView() {
    _isGridView = false;
    return this;
  }

  AppSettingsBuilder withGridViewEnabled() {
    _isGridView = true;
    return this;
  }

  AppSettings build() {
    return AppSettings(
      themeMode: _themeMode,
      isGridView: _isGridView,
      subtitlesEnabled: _subtitlesEnabled,
      videoDecoder: _videoDecoder,
      hardwareAcceleration: _hardwareAcceleration,
    );
  }
}

/// Utility class for creating collections of test data
class TestDataCollections {
  /// Creates a list of video files with different statuses
  static List<VideoFile> createMixedVideoList() {
    return [
      VideoFileBuilder()
          .withPath('/test/video1.mp4')
          .withName('New Video')
          .withStatus(VideoStatus.new_)
          .build(),
      VideoFileBuilder()
          .withPath('/test/video2.mp4')
          .withName('Favorite Video')
          .asFavorite()
          .asPartiallyWatched()
          .build(),
      VideoFileBuilder()
          .withPath('/test/video3.mp4')
          .withName('Watched Video')
          .asWatched()
          .build(),
      VideoFileBuilder()
          .withPath('/test/video4.mp4')
          .withName('Large Video')
          .withFileSize(5000000)
          .withDuration(const Duration(hours: 2))
          .build(),
    ];
  }

  /// Creates a list of favorite videos
  static List<VideoFile> createFavoriteVideoList() {
    return [
      VideoFileBuilder()
          .withPath('/test/fav1.mp4')
          .withName('Favorite 1')
          .asFavorite()
          .build(),
      VideoFileBuilder()
          .withPath('/test/fav2.mp4')
          .withName('Favorite 2')
          .asFavorite()
          .asWatched()
          .build(),
    ];
  }

  /// Creates a list of recently watched videos
  static List<VideoFile> createRecentlyWatchedList() {
    final now = DateTime.now();
    return [
      VideoFileBuilder()
          .withPath('/test/recent1.mp4')
          .withName('Recent 1')
          .withLastPlayedAt(now.subtract(const Duration(hours: 1)))
          .asPartiallyWatched()
          .build(),
      VideoFileBuilder()
          .withPath('/test/recent2.mp4')
          .withName('Recent 2')
          .withLastPlayedAt(now.subtract(const Duration(hours: 2)))
          .asWatched()
          .build(),
    ];
  }

  /// Creates an empty video list
  static List<VideoFile> createEmptyVideoList() {
    return [];
  }

  /// Creates a large video list for performance testing
  static List<VideoFile> createLargeVideoList({int count = 100}) {
    return List.generate(
        count,
        (index) => VideoFileBuilder()
            .withPath('/test/video_$index.mp4')
            .withName('Video $index')
            .withFileSize(1000000 + (index * 10000))
            .build());
  }
}

/// Utility class for creating test scenarios
class TestScenarios {
  /// Creates a scenario with permission denied error
  static Exception createPermissionDeniedException() {
    return Exception('Permission denied');
  }

  /// Creates a scenario with network error
  static Exception createNetworkException() {
    return Exception('Network error');
  }

  /// Creates a scenario with file not found error
  static Exception createFileNotFoundException() {
    return Exception('File not found');
  }

  /// Creates a scenario with storage full error
  static Exception createStorageFullException() {
    return Exception('Storage full');
  }
}
