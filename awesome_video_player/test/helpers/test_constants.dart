import 'dart:ui';

/// Test constants used across all test files
class TestConstants {
  // Test file paths
  static const String testVideoPath = '/test/video.mp4';
  static const String testThumbnailPath = '/test/thumbnail.jpg';
  static const String testVideoPath2 = '/test/video2.mp4';
  static const String testVideoPath3 = '/test/video3.mp4';

  // Test video names
  static const String testVideoName = 'Test Video';
  static const String testVideoName2 = 'Test Video 2';
  static const String testVideoName3 = 'Test Video 3';

  // Test durations
  static const Duration shortDuration = Duration(minutes: 2);
  static const Duration mediumDuration = Duration(minutes: 30);
  static const Duration longDuration = Duration(hours: 2);

  // Test file sizes (in bytes)
  static const int smallFileSize = 1024 * 1024; // 1MB
  static const int mediumFileSize = 100 * 1024 * 1024; // 100MB
  static const int largeFileSize = 1024 * 1024 * 1024; // 1GB

  // Test search queries
  static const String searchQuery = 'test';
  static const String emptySearchQuery = '';
  static const String noResultsSearchQuery = 'xyz123';

  // Test error messages
  static const String permissionDeniedMessage =
      'Permission denied. Please grant photo library access in settings.';
  static const String networkErrorMessage = 'Network error occurred';
  static const String fileNotFoundMessage = 'File not found';
  static const String genericErrorMessage = 'An error occurred';

  // Test timeouts
  static const Duration shortTimeout = Duration(seconds: 5);
  static const Duration mediumTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);

  // Test widget keys
  static const String videoListKey = 'video_list';
  static const String videoPlayerKey = 'video_player';
  static const String settingsPageKey = 'settings_page';
  static const String splashScreenKey = 'splash_screen';
  static const String searchBarKey = 'search_bar';
  static const String favoriteButtonKey = 'favorite_button';
  static const String playButtonKey = 'play_button';
  static const String pauseButtonKey = 'pause_button';
  static const String themeToggleKey = 'theme_toggle';
  static const String gridViewToggleKey = 'grid_view_toggle';

  // Test preferences keys
  static const String themePreferenceKey = 'theme_mode';
  static const String gridViewPreferenceKey = 'grid_view';
  static const String subtitlesPreferenceKey = 'subtitles_enabled';
  static const String lastPlayedVideoKey = 'last_played_video';
  static const String videoMetadataKey = 'video_metadata';

  // Test JSON data
  static const Map<String, dynamic> testVideoJson = {
    'path': testVideoPath,
    'name': testVideoName,
    'thumbnailPath': testThumbnailPath,
    'duration': 300000, // 5 minutes in milliseconds
    'fileSize': mediumFileSize,
    'dateAdded': 1640995200000, // 2022-01-01 in milliseconds
    'lastPlayedPosition': 0,
    'lastPlayedAt': null,
    'status': 0, // VideoStatus.new_
    'isFavorite': false,
  };

  static const Map<String, dynamic> testAppSettingsJson = {
    'themeMode': 0, // ThemeMode.system
    'isGridView': true,
    'subtitlesEnabled': false,
    'videoDecoder': 'auto',
    'hardwareAcceleration': true,
  };

  // Test animation durations
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const Duration slideAnimationDuration = Duration(milliseconds: 250);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 200);

  // Test scroll offsets
  static const Offset scrollUpOffset = Offset(0, -300);
  static const Offset scrollDownOffset = Offset(0, 300);
  static const Offset scrollLeftOffset = Offset(-300, 0);
  static const Offset scrollRightOffset = Offset(300, 0);

  // Test video player positions
  static const Duration startPosition = Duration.zero;
  static const Duration middlePosition = Duration(minutes: 15);
  static const Duration endPosition = Duration(minutes: 29, seconds: 59);

  // Test batch sizes for performance testing
  static const int smallBatchSize = 10;
  static const int mediumBatchSize = 50;
  static const int largeBatchSize = 100;
  static const int extraLargeBatchSize = 500;

  // Test retry counts
  static const int maxRetryCount = 3;
  static const int defaultRetryCount = 1;

  // Test cache sizes
  static const int smallCacheSize = 10;
  static const int mediumCacheSize = 50;
  static const int largeCacheSize = 100;
}
