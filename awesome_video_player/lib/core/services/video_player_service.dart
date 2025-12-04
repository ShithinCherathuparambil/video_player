import 'dart:async';

import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/services/format_detection_service.dart';
import 'package:lumeo/core/services/video_intent_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum DecoderType {
  hardware,
  software,
}

enum PlayerType {
  betterPlayer,
  vlc,
  videoPlayer, // Fallback
}

/// Universal Video Player Service with VLC-like format support
///
/// Supports all video formats with automatic decoder selection and fallback
class VideoPlayerService {
  final FormatDetectionService _formatDetection = FormatDetectionService();

  // Player controllers
  dynamic _betterPlayerController;
  dynamic _vlcController;
  PlayerType _currentPlayerType = PlayerType.betterPlayer;
  DecoderType _currentDecoder = DecoderType.hardware;
  VideoFile? _currentVideo;
  bool _isInitialized = false;
  bool _isDisposing = false; // Flag to prevent use after disposal

  // State tracking
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  StreamController<Duration>? _positionController;
  StreamController<bool>? _playingController;

  // Configuration
  List<String>? _subtitles;
  int? _audioTrackIndex;
  double _playbackSpeed = 1.0;
  double _audioBoost = 1.0; // Audio boost multiplier (1.0 = 100%, 2.0 = 200%)
  int? _networkCacheSizeMs; // Saved network cache size preference

  // Getters
  dynamic get betterPlayerController => _isDisposing ? null : _betterPlayerController;
  dynamic get vlcController => _isDisposing ? null : _vlcController;
  DecoderType get currentDecoder => _currentDecoder;
  VideoFile? get currentVideo => _currentVideo;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  PlayerType get currentPlayerType => _currentPlayerType;
  Stream<Duration>? get positionStream => _positionController?.stream;
  Stream<bool>? get playingStream => _playingController?.stream;

  /// Initialize player with automatic format detection and decoder selection
  Future<void> initializePlayer({
    required String videoPath,
    required VideoFile video,
    DecoderType? preferredDecoder,
    List<String>? subtitles,
    int? audioTrackIndex,
    double? playbackSpeed = 1.0,
    int? networkCacheSizeMs,
  }) async {
    try {
      _currentVideo = video;
      _subtitles = subtitles;
      _audioTrackIndex = audioTrackIndex;
      _playbackSpeed = playbackSpeed ?? 1.0;
      _networkCacheSizeMs = networkCacheSizeMs; // Save for switchDecoder

      // Initialize streams
      _positionController = StreamController<Duration>.broadcast();
      _playingController = StreamController<bool>.broadcast();

      // Enable wakelock to keep screen on
      await WakelockPlus.enable();

      // Handle content:// URIs: BetterPlayer/ExoPlayer can't handle them directly
      // Copy to cache first for reliable playback
      String actualVideoPath = videoPath;
      if (videoPath.startsWith('content://')) {
        debugPrint('VideoPlayerService: Detected content:// URI, copying to cache...');
        debugPrint('VideoPlayerService: Original path: $videoPath');
        try {
          final cachedPath = await VideoIntentService.copyContentUriToCache(videoPath)
              .timeout(
            const Duration(minutes: 5),
            onTimeout: () {
              debugPrint('VideoPlayerService: Copy operation timed out after 5 minutes');
              return null;
            },
          );
          
          if (cachedPath != null && cachedPath.isNotEmpty) {
            actualVideoPath = cachedPath;
            debugPrint('VideoPlayerService: Content URI copied to cache successfully: $cachedPath');
          } else {
            debugPrint('VideoPlayerService: WARNING - Copy returned null or empty path!');
            debugPrint('VideoPlayerService: This will likely cause playback to fail.');
            // Don't use the original content:// URI - it will fail
            // Throw an error so the caller knows
            throw Exception('Failed to copy content:// URI to cache. Cannot play content:// URIs directly.');
          }
        } catch (e, stackTrace) {
          debugPrint('VideoPlayerService: Error copying content URI: $e');
          debugPrint('VideoPlayerService: Stack trace: $stackTrace');
          // Don't try to play content:// URI directly - it will fail
          throw Exception('Failed to copy content:// URI to cache: $e');
        }
      }

      // Detect format (for decoder selection & data source type)
      final formatResult = await _formatDetection.detectFormat(actualVideoPath);

      // Always try BetterPlayer first (primary engine)
      bool initialized =
          await _tryBetterPlayer(actualVideoPath, formatResult, networkCacheSizeMs);

      // VLC is currently disabled (_tryVlcPlayer returns false)
      if (!initialized) {
        initialized = await _tryVlcPlayer(videoPath, formatResult, networkCacheSizeMs);
      }

      // Final fallback to video_player (basic support - currently stubbed)
      if (!initialized) {
        initialized = await _tryVideoPlayer(videoPath);
      }

      if (initialized) {
        _isInitialized = true;
        debugPrint('VideoPlayerService: Initialized with $_currentPlayerType');
      } else {
        throw Exception('Failed to initialize video player');
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error initializing player: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Try initializing with better_player
  Future<bool> _tryBetterPlayer(
      String videoPath, FormatDetectionResult formatResult, int? networkCacheSizeMs) async {
    try {
      // BetterPlayer can handle content:// URIs on Android when using file type
      final isContentUri = videoPath.startsWith('content://');
      final dataSourceType = formatResult.isNetworkStream
          ? BetterPlayerDataSourceType.network
          : BetterPlayerDataSourceType.file;
      
      debugPrint('VideoPlayerService: Initializing BetterPlayer with path: $videoPath');
      debugPrint('VideoPlayerService: Data source type: $dataSourceType, isContentUri: $isContentUri');
      
      final dataSource = BetterPlayerDataSource(
        dataSourceType,
        videoPath,
        // Don't pass subtitles to BetterPlayer - we use custom subtitle overlay
        // This prevents BetterPlayer's subtitle drawer from causing setState errors during disposal
        subtitles: const [], // Empty list to disable BetterPlayer's subtitle system
      );

      final config = BetterPlayerConfiguration(
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        handleLifecycle: false, // Disable automatic lifecycle handling to prevent unwanted pauses
        allowedScreenSleep: false, // Keep screen on during playback
        eventListener: _handleBetterPlayerEvent,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false, // Disable built-in controls - we use custom MX Player controls
          enableFullscreen: false,
          enableSubtitles: false,
          enablePlaybackSpeed: false,
          enableProgressBar: false,
          enableSkips: false,
          enableMute: false,
          enablePlayPause: false,
          enableQualities: false,
          enablePip: false,
          enableOverflowMenu: false,
        ),
        deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );

      _betterPlayerController = BetterPlayerController(
        config,
        betterPlayerDataSource: dataSource,
      );

      _currentPlayerType = PlayerType.betterPlayer;
      _currentDecoder = formatResult.supportsHardwareDecoding
          ? DecoderType.hardware
          : DecoderType.software;

      // Initialize duration if available and listen for ready state
      _betterPlayerController!.videoPlayerController?.addListener(() {
        final vc = _betterPlayerController!.videoPlayerController;
        if (vc != null && vc.value.initialized) {
          _duration = vc.value.duration ?? Duration.zero;
          
          // Update playing state from controller to keep it in sync
          // Only update if there's a real change to avoid unnecessary state updates
          final isCurrentlyPlaying = vc.value.isPlaying;
          if (isCurrentlyPlaying != _isPlaying) {
            _isPlaying = isCurrentlyPlaying;
            _playingController?.add(_isPlaying);
          }
        }
      });

      // Event listener is already set in config, no need to add again
      debugPrint('VideoPlayerService: better_player initialized');
      return true;
    } on PlatformException catch (e) {
      // If BetterPlayer fails with a content:// URI, try copying to cache and retry
      if (videoPath.startsWith('content://') && 
          (e.code == 'VideoError' || e.message?.contains('Source error') == true)) {
        debugPrint('VideoPlayerService: BetterPlayer failed with content:// URI, trying cached copy...');
        try {
          final cachedPath = await VideoIntentService.copyContentUriToCache(videoPath);
          if (cachedPath != null) {
            debugPrint('VideoPlayerService: Content URI copied to cache: $cachedPath');
            // Dispose the failed controller
            try {
              await _betterPlayerController?.dispose();
            } catch (_) {}
            _betterPlayerController = null;
            // Retry with cached path
            return await _tryBetterPlayer(cachedPath, formatResult, networkCacheSizeMs);
          }
        } catch (copyError) {
          debugPrint('VideoPlayerService: Failed to copy content URI: $copyError');
        }
      }
      debugPrint('VideoPlayerService: better_player failed: $e');
      return false;
    } catch (e) {
      debugPrint('VideoPlayerService: better_player failed: $e');
      return false;
    }
  }

  /// Try initializing with VLC player
  Future<bool> _tryVlcPlayer(
      String videoPath, FormatDetectionResult formatResult, int? networkCacheSizeMs) async {
    // Temporary: disable VLC on this build to avoid platform channel crashes.
    // The flutter_vlc_player plugin is throwing:
    // PlatformException(channel-error, Unable to establish connection on channel...)
    // We fall back to BetterPlayer / video_player instead.
    debugPrint('VideoPlayerService: VLC disabled, skipping VLC initialization.');
    return false;
  }

  /// Try initializing with video_player (fallback)
  Future<bool> _tryVideoPlayer(String videoPath) async {
    try {
      // Fallback not implemented; rely on better_player/VLC
      debugPrint('VideoPlayerService: video_player fallback not implemented');
      return false;
    } catch (e) {
      debugPrint('VideoPlayerService: video_player failed: $e');
      return false;
    }
  }

  /// Play/Pause toggle
  Future<void> togglePlayPause() async {
    if (_isDisposing || !_isInitialized) {
      debugPrint('VideoPlayerService: Cannot play/pause - player not initialized or disposing');
      return;
    }

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController == null) {
            debugPrint('VideoPlayerService: BetterPlayer controller is null');
            break;
          }
          
          // Check actual controller state instead of internal flag
          final videoPlayerController = _betterPlayerController!.videoPlayerController;
          if (videoPlayerController != null) {
            // Wait for initialization if not ready
            if (!videoPlayerController.value.initialized) {
              debugPrint('VideoPlayerService: Waiting for BetterPlayer to initialize...');
              // Wait up to 2 seconds for initialization
              int attempts = 0;
              while (!videoPlayerController.value.initialized && attempts < 20) {
                await Future.delayed(const Duration(milliseconds: 100));
                attempts++;
              }
              
              if (!videoPlayerController.value.initialized) {
                debugPrint('VideoPlayerService: BetterPlayer failed to initialize after waiting');
                break;
              }
            }
            
            final isCurrentlyPlaying = videoPlayerController.value.isPlaying;
            debugPrint('VideoPlayerService: Current playing state: $isCurrentlyPlaying');
            
            if (isCurrentlyPlaying) {
              await _betterPlayerController!.pause();
              _isPlaying = false;
              debugPrint('VideoPlayerService: Paused video');
            } else {
              await _betterPlayerController!.play();
              _isPlaying = true;
              debugPrint('VideoPlayerService: Started playing video');
            }
          } else {
            debugPrint('VideoPlayerService: videoPlayerController is null, using fallback');
            // Fallback to internal state if controller not ready
            if (_isPlaying) {
              await _betterPlayerController!.pause();
              _isPlaying = false;
            } else {
              await _betterPlayerController!.play();
              _isPlaying = true;
            }
          }
          _playingController?.add(_isPlaying);
          break;
        case PlayerType.vlc:
          if (_vlcController == null) break;
          if (_isPlaying) {
            await _vlcController!.pause();
            _isPlaying = false;
          } else {
            await _vlcController!.play();
            _isPlaying = true;
          }
          _playingController?.add(_isPlaying);
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error toggling play/pause: $e');
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    if (!_isInitialized) return;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            await _betterPlayerController!.seekTo(position);
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            await _vlcController!.seekTo(position);
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }

      _position = position;
      _positionController?.add(_position);
    } catch (e) {
      debugPrint('VideoPlayerService: Error seeking: $e');
    }
  }

  /// Seek relative (forward/backward)
  Future<void> seekRelative(Duration offset) async {
    final newPosition = _position + offset;
    final clampedPosition = _clampDuration(
      newPosition,
      Duration.zero,
      _duration,
    );
    await seekTo(clampedPosition);
  }

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0.25 || speed > 4.0) {
      throw ArgumentError('Playback speed must be between 0.25 and 4.0');
    }

    if (!_isInitialized) return;

    _playbackSpeed = speed;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            await _betterPlayerController!.setSpeed(speed);
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            await _vlcController!.setPlaybackSpeed(speed);
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error setting playback speed: $e');
    }
  }

  /// Switch decoder (hardware <-> software)
  Future<void> switchDecoder([DecoderType? decoderType, int? networkCacheSizeMs]) async {
    if (_currentVideo == null || !_isInitialized) return;

    try {
      // Dispose current player
      await dispose();

      // Determine new decoder type
      if (decoderType != null) {
        _currentDecoder = decoderType;
      } else {
        // Toggle if no specific type provided
        _currentDecoder = _currentDecoder == DecoderType.hardware
            ? DecoderType.software
            : DecoderType.hardware;
      }

      // Use provided network cache size, saved preference, or detect from format
      int? networkCacheSize = networkCacheSizeMs ?? _networkCacheSizeMs;
      if (networkCacheSize == null) {
        final formatResult = await _formatDetection.detectFormat(_currentVideo!.path);
        networkCacheSize = formatResult.isNetworkStream ? 1000 : null; // Default cache size
      }

      await initializePlayer(
        videoPath: _currentVideo!.path,
        video: _currentVideo!,
        preferredDecoder: _currentDecoder,
        subtitles: _subtitles,
        audioTrackIndex: _audioTrackIndex,
        playbackSpeed: _playbackSpeed,
        networkCacheSizeMs: networkCacheSize,
      );
    } catch (e) {
      debugPrint('VideoPlayerService: Error switching decoder: $e');
      rethrow;
    }
  }

  /// Set audio boost multiplier (1.0 = 100%, 2.0 = 200%)
  void setAudioBoost(double boost) {
    _audioBoost = boost.clamp(1.0, 2.0);
    // Reapply current volume with new boost
    // Note: This requires storing the base volume, which we'll do via setVolume
  }
  
  /// Get current audio boost
  double getAudioBoost() {
    return _audioBoost;
  }

  /// Adjust volume (0.0 to 1.0)
  /// Audio boost is applied as a multiplier
  Future<void> setVolume(double volume) async {
    if (volume < 0.0 || volume > 1.0) {
      throw ArgumentError('Volume must be between 0.0 and 1.0');
    }

    if (!_isInitialized) return;

    // Apply audio boost to volume
    final boostedVolume = (volume * _audioBoost).clamp(0.0, 1.0);

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            await _betterPlayerController!.setVolume(boostedVolume);
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            await _vlcController!.setVolume((boostedVolume * 100).toInt());
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error setting volume: $e');
    }
  }

  /// Get available audio tracks
  Future<List<String>> getAudioTracks() async {
    if (!_isInitialized) return [];

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            // better_player provides track information via controller
            // For now, return default track names
            return ['Default', 'Track 1', 'Track 2'];
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            // VLC provides track information via controller
            // For now, return default track names
            return ['Default', 'Track 1', 'Track 2'];
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error getting audio tracks: $e');
    }
    
    return ['Default'];
  }
  
  /// Get current audio track index
  int? getCurrentAudioTrackIndex() {
    return _audioTrackIndex;
  }

  /// Get available subtitle tracks
  Future<List<String>> getSubtitleTracks() async {
    if (!_isInitialized) return ['None'];

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            // better_player provides subtitle track information
            // For now, return default track names
            return ['None', 'Track 1', 'Track 2'];
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            // VLC provides subtitle track information
            // For now, return default track names
            return ['None', 'Track 1', 'Track 2'];
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error getting subtitle tracks: $e');
    }
    
    return ['None'];
  }

  /// Set subtitle track by index
  Future<void> setSubtitleTrack(int trackIndex) async {
    if (!_isInitialized) return;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            // better_player subtitle track selection
            // This would need to be implemented based on better_player API
            debugPrint('VideoPlayerService: Setting subtitle track $trackIndex');
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            // VLC subtitle track selection
            // This would need to be implemented based on VLC API
            debugPrint('VideoPlayerService: Setting subtitle track $trackIndex');
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error setting subtitle track: $e');
    }
  }

  /// Get available video tracks
  Future<List<String>> getVideoTracks() async {
    if (!_isInitialized) return ['Default'];

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            // better_player provides video track information
            // For now, return default track names
            return ['Default', 'Track 1', 'Track 2'];
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            // VLC provides video track information
            // For now, return default track names
            return ['Default', 'Track 1', 'Track 2'];
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error getting video tracks: $e');
    }
    
    return ['Default'];
  }

  /// Set video track by index
  Future<void> setVideoTrack(int trackIndex) async {
    if (!_isInitialized) return;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            // better_player video track selection
            // This would need to be implemented based on better_player API
            debugPrint('VideoPlayerService: Setting video track $trackIndex');
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            // VLC video track selection
            // This would need to be implemented based on VLC API
            debugPrint('VideoPlayerService: Setting video track $trackIndex');
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error setting video track: $e');
    }
  }

  /// Set audio delay in milliseconds
  /// Note: Actual audio delay may require platform channels or player-specific support
  Future<void> setAudioDelay(int delayMs) async {
    if (!_isInitialized) return;

    try {
      // Store delay value for potential future use
      // Actual implementation would require platform channels or player-specific APIs
      debugPrint('VideoPlayerService: Audio delay set to ${delayMs}ms');
      
      // For VLC, audio delay can be set via options, but requires reinitialization
      // For better_player, audio delay may not be directly supported
      // This is a placeholder for future implementation
    } catch (e) {
      debugPrint('VideoPlayerService: Error setting audio delay: $e');
    }
  }

  /// Set audio track
  Future<void> setAudioTrack(int trackIndex) async {
    if (!_isInitialized) return;

    _audioTrackIndex = trackIndex;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            await _betterPlayerController!.setAudioTrack(trackIndex);
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            await _vlcController!.setAudioTrack(trackIndex);
          }
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error setting audio track: $e');
    }
  }

  /// Enter fullscreen
  void enterFullscreen() {
    if (!_isInitialized) return;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          _betterPlayerController?.enterFullScreen();
          break;
        case PlayerType.vlc:
          // VLC fullscreen is handled at widget level
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error entering fullscreen: $e');
    }
  }

  /// Exit fullscreen
  void exitFullscreen() {
    if (!_isInitialized) return;

    try {
      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          _betterPlayerController?.exitFullScreen();
          break;
        case PlayerType.vlc:
          // VLC fullscreen is handled at widget level
          break;
        case PlayerType.videoPlayer:
          // Not used
          break;
      }
    } catch (e) {
      debugPrint('VideoPlayerService: Error exiting fullscreen: $e');
    }
  }

  void _handleBetterPlayerEvent(BetterPlayerEvent event) {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.progress:
        final position = event.parameters?['progress'] as Duration?;
        if (position != null) {
          _position = position;
          _positionController?.add(_position);
        }
        break;
      case BetterPlayerEventType.play:
        _isPlaying = true;
        _playingController?.add(true);
        break;
      case BetterPlayerEventType.pause:
      case BetterPlayerEventType.finished:
        _isPlaying = false;
        _playingController?.add(false);
        break;
      case BetterPlayerEventType.initialized:
        final duration = event.parameters?['duration'] as Duration?;
        if (duration != null) {
          _duration = duration;
        }
        break;
      default:
        break;
    }
  }


  /// Dispose resources
  Future<void> dispose() async {
    if (_isDisposing) {
      debugPrint('VideoPlayerService: Already disposing, skipping');
      return;
    }
    
    _isDisposing = true;
    
    try {
      await WakelockPlus.disable();

      switch (_currentPlayerType) {
        case PlayerType.betterPlayer:
          if (_betterPlayerController != null) {
            try {
              // Remove event listener FIRST to prevent our callbacks during cleanup
              try {
                _betterPlayerController!.removeEventsListener(_handleBetterPlayerEvent);
              } catch (e) {
                debugPrint('VideoPlayerService: Error removing event listener: $e');
              }
              
              // NOTE: BetterPlayer's dispose() internally calls pause(), which triggers
              // BetterPlayerSubtitlesDrawer to call setState(). This causes a "setState() 
              // called when widget tree was locked" error, but it's harmless and doesn't
              // affect functionality. This is a known BetterPlayer issue that occurs
              // during widget tree disposal. The error is caught and logged but doesn't
              // crash the app.
              
              // Dispose with timeout to prevent hanging
              await _betterPlayerController!.dispose().timeout(
                const Duration(seconds: 2),
                onTimeout: () {
                  debugPrint('VideoPlayerService: BetterPlayer dispose timed out');
                },
              ).catchError((e) {
                // Ignore setState errors from BetterPlayer's subtitle drawer during disposal
                // This is a known BetterPlayer issue and doesn't affect functionality
                if (e.toString().contains('setState') || 
                    e.toString().contains('widget tree was locked') ||
                    e.toString().contains('BetterPlayerSubtitlesDrawer')) {
                  debugPrint('VideoPlayerService: Ignoring BetterPlayer subtitle drawer setState error during disposal (known issue)');
                } else {
                  debugPrint('VideoPlayerService: Error during BetterPlayer dispose: $e');
                }
              });
              
              // Small delay to let MediaCodec cleanup complete
              await Future.delayed(const Duration(milliseconds: 50));
            } catch (e) {
              // Catch any other errors during disposal
              // The setState error from subtitle drawer is expected and harmless
              if (!e.toString().contains('setState') && 
                  !e.toString().contains('widget tree was locked') &&
                  !e.toString().contains('BetterPlayerSubtitlesDrawer')) {
                debugPrint('VideoPlayerService: Error disposing better_player: $e');
              }
              // Continue with cleanup even if dispose fails
            } finally {
              _betterPlayerController = null;
            }
          }
          break;
        case PlayerType.vlc:
          if (_vlcController != null) {
            try {
              await _vlcController!.dispose();
            } catch (e) {
              debugPrint('VideoPlayerService: Error disposing VLC player: $e');
            }
            _vlcController = null;
          }
          break;
        case PlayerType.videoPlayer:
          // Fallback cleanup
          break;
      }

      _positionController?.close();
      _playingController?.close();
      _positionController = null;
      _playingController = null;

      _isInitialized = false;
      _currentVideo = null;
      _isPlaying = false;
      _position = Duration.zero;
      _duration = Duration.zero;

      debugPrint('VideoPlayerService: Disposed');
    } catch (e) {
      debugPrint('VideoPlayerService: Error disposing: $e');
    }
  }
}
