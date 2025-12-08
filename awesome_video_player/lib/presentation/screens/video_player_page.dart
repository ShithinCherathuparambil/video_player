import 'dart:async'; // Added for Timer and StreamSubscription
import 'dart:io';
import 'dart:math';
import 'dart:ui'; // For ImageFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_state.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:lumeo/domain/usecases/save_video_metadata.dart';
import 'package:lumeo/data/repositories/video_repository_impl.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/presentation/widgets/audio_equalizer.dart';
import 'package:lumeo/presentation/widgets/video_effects_panel.dart';
import 'package:lumeo/presentation/widgets/advanced_features_panel.dart';
import 'package:lumeo/presentation/widgets/floating_video_controls.dart';
import 'package:lumeo/core/services/advanced_features_service.dart';
import 'package:lumeo/core/services/video_player_service.dart' as vps;
import 'package:lumeo/core/services/format_detection_service.dart';

import 'package:lumeo/core/utils/error_handler.dart';
import 'package:lumeo/core/services/playback_position_service.dart';
import 'package:lumeo/core/services/subtitle_service.dart';
import 'package:lumeo/presentation/widgets/player/subtitle_overlay.dart';
import 'package:lumeo/domain/entities/subtitle.dart';
import 'package:lumeo/core/services/audio_equalizer_service.dart';
import 'package:lumeo/core/services/audio_boost_service.dart';
import 'package:lumeo/presentation/screens/playlist_viewer_page.dart';
import 'package:lumeo/presentation/widgets/chapter_navigator.dart';
import 'package:lumeo/core/services/chapter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumeo/presentation/widgets/video_fit_mode_selector.dart';
import 'package:lumeo/presentation/widgets/mx_player_controls.dart';

class VideoPlayerPage extends StatefulWidget {
  final VideoFile video;
  final bool resumeFromLastPosition;

  const VideoPlayerPage({
    super.key,
    required this.video,
    this.resumeFromLastPosition = false,
  });

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with TickerProviderStateMixin {
  vps.VideoPlayerService? _playerService;
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isInitialized = false;

  Duration _lastPosition = Duration.zero;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;

  late SaveVideoMetadata _saveVideoMetadata;
  late VideoFile _currentVideo;
  final AdvancedFeaturesService _advancedFeaturesService =
      AdvancedFeaturesService();
  final PlaybackPositionService _playbackPositionService =
      PlaybackPositionService();
  final SubtitleService _subtitleService = SubtitleService();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  Timer? _controlsHideTimer;

  // Video Controls
  bool _subtitlesEnabled = true;
  double _volume = 1.0;
  double _audioBoost = 1.0; // 1.0 = 100%, 2.0 = 200%
  double _playbackSpeed = 1.0;

  // Subtitle state
  Subtitle? _currentSubtitle;
  SubtitleSettings _subtitleSettings = const SubtitleSettings();
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _hue = 0.0;
  double _gamma = 1.0;

  // Aspect ratio controls
  double _aspectRatio = 16 / 9;
  double _originalAspectRatio = 16 / 9;
  final List<double> _aspectRatios = [16 / 9, 4 / 3, 1 / 1, 21 / 9, 2.35 / 1];
  int _currentAspectRatioIndex = 0;

  // Video fit mode controls
  BoxFit _videoFitMode =
      BoxFit.contain; // Default: fit to screen preserving aspect ratio

  // Playback controls

  bool _shuffleEnabled = false;
  bool _autoPlayNext = true;
  bool _rememberPosition = true;
  bool _showTimeRemaining = true;
  bool _showBuffering = true;
  bool _showQuality = true;

  // Advanced features
  bool _hardwareAcceleration = true;
  bool _deinterlace = false;
  bool _frameDrop = true;
  bool _networkCaching = true;
  int _networkCacheSize = 1000; // ms
  bool _audioSync = true;
  double _audioDelay = 0.0;
  double _subtitleDelay = 0.0;

  // Audio equalizer
  List<double> _equalizerGains = List.filled(10, 0.0);

  // Video effects
  String _selectedFilter = 'None';
  double _rotation = 0.0; // VLC-style rotation (0, 90, 180, 270)

  // Advanced features
  String _selectedQuality = 'Auto';
  String _selectedAudioTrack = 'Default';
  String _selectedSubtitleTrack = 'None';
  String _selectedVideoTrack = 'Default';
  bool _backgroundPlayEnabled = false;
  String _loopMode = 'Off'; // 'Off', 'One', 'All'

  // Track Lists
  List<String> _availableAudioTracks = [];
  List<String> _availableSubtitleTracks = [];

  // UI State
  bool _showStatistics = false;

  // Cinematic Ambient Mode
  bool _ambientModeEnabled = false;

  AnimationController? _controlsAnimationController;

  // Playback statistics
  double _fps = 0.0;
  double _bitrate = 0.0;
  String _resolution = '';
  Duration _bufferDuration = Duration.zero;

  FormatDetectionResult? _formatResult;

  // UI State - Interaction
  bool _isLocked = false;
  double _videoScale = 1.0;

  // Gesture State
  bool _isDragging = false;
  String? _dragType; // 'Volume', 'Brightness', 'Seek'
  double _dragValue = 0.0;
  Duration _dragTargetTime = Duration.zero;
  String _dragLabel = '';
  IconData? _dragIcon;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _initializeDependencies();
    _initializeAnimations();

    // Load preferences BEFORE initializing player
    _loadPreferencesAndInitialize();
  }

  Future<void> _loadPreferencesAndInitialize() async {
    // Load preferences from theme bloc
    final themeState = context.read<ThemeBloc>().state;
    if (themeState is ThemeLoaded) {
      setState(() {
        _subtitlesEnabled = themeState.subtitlesEnabled;
      });
    }

    // Load advanced features preferences
    await _loadAdvancedFeaturesPreferences();

    // Load equalizer preset
    await _loadEqualizerPreset();

    // Load fit mode preference
    await _loadFitModePreference();

    // Now initialize player with loaded preferences
    // Audio boost will be loaded after player initialization
    _initializePlayer();
  }

  Future<void> _loadAudioBoost() async {
    try {
      final audioBoostService = AudioBoostService();
      final boost = await audioBoostService.getBoost();
      setState(() {
        _audioBoost = boost;
      });
      // Apply boost to player service when it's initialized
      if (_playerService != null) {
        _playerService!.setAudioBoost(boost);
      }
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._loadAudioBoost');
    }
  }

  Future<void> _applyAudioBoost(double boost) async {
    try {
      setState(() {
        _audioBoost = boost;
      });
      final audioBoostService = AudioBoostService();
      await audioBoostService.saveBoost(boost);
      if (_playerService != null) {
        _playerService!.setAudioBoost(boost);
        // Reapply current volume with new boost
        if (_isInitialized) {
          await _playerService!.setVolume(_volume);
        }
      }
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._applyAudioBoost');
    }
  }

  void _initializeDependencies() {
    final videoRepository = VideoRepositoryImpl(
      localDataSource: VideoLocalDataSourceImpl(),
    );
    _saveVideoMetadata = SaveVideoMetadata(videoRepository);
  }

  Future<void> _loadAdvancedFeaturesPreferences() async {
    final prefs = await _advancedFeaturesService.loadPreferences();
    if (mounted) {
      setState(() {
        _hardwareAcceleration = prefs['hardwareAcceleration'] ?? true;
        _deinterlace = prefs['deinterlace'] ?? false;
        _frameDrop = prefs['frameDrop'] ?? true;
        _networkCaching = prefs['networkCaching'] ?? true;
        _networkCacheSize = prefs['networkCacheSize'] ?? 1000;
        _audioSync = prefs['audioSync'] ?? true;
        _audioDelay = (prefs['audioDelay'] ?? 0.0).toDouble();
        _subtitleDelay = (prefs['subtitleDelay'] ?? 0.0).toDouble();
        _showTimeRemaining = prefs['showTimeRemaining'] ?? true;
        _showBuffering = prefs['showBuffering'] ?? true;
        _showQuality = prefs['showQuality'] ?? true;
        _rememberPosition = prefs['rememberPosition'] ?? true;
        _autoPlayNext = prefs['autoPlayNext'] ?? true;
        _shuffleEnabled = prefs['shuffleEnabled'] ?? false;

        // Also load quality and track selections
        _selectedQuality = prefs['selectedQuality'] ?? 'Auto';
        _selectedAudioTrack = prefs['selectedAudioTrack'] ?? 'Default';
        _selectedSubtitleTrack = prefs['selectedSubtitleTrack'] ?? 'None';
        _selectedSubtitleTrack = prefs['selectedSubtitleTrack'] ?? 'None';
        _selectedVideoTrack = prefs['selectedVideoTrack'] ?? 'Default';
        _backgroundPlayEnabled = prefs['backgroundPlayEnabled'] ?? false;
        _loopMode = prefs['loopMode'] ?? 'Off';

        // Apply initial settings
        if (_playerService != null) {
          _playerService!.enableBackgroundPlay(_backgroundPlayEnabled);
          if (_loopMode == 'One') {
            _playerService!.setLooping(true);
          } else {
            _playerService!.setLooping(false);
          }
        }
      });
    }
  }

  Future<void> _saveAdvancedFeaturesPreferences() async {
    await _advancedFeaturesService.savePreferences(
      hardwareAcceleration: _hardwareAcceleration,
      deinterlace: _deinterlace,
      frameDrop: _frameDrop,
      networkCaching: _networkCaching,
      networkCacheSize: _networkCacheSize,
      audioSync: _audioSync,
      audioDelay: _audioDelay,
      subtitleDelay: _subtitleDelay,
      showTimeRemaining: _showTimeRemaining,
      showBuffering: _showBuffering,
      showQuality: _showQuality,
      rememberPosition: _rememberPosition,
      autoPlayNext: _autoPlayNext,
      shuffleEnabled: _shuffleEnabled,
      selectedQuality: _selectedQuality,
      selectedAudioTrack: _selectedAudioTrack,
      selectedSubtitleTrack: _selectedSubtitleTrack,
      selectedVideoTrack: _selectedVideoTrack,
    );
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimationController.forward();
  }

  Future<void> _loadTracks() async {
    if (_playerService == null) return;

    final audioTracks = await _playerService!.getAudioTracks();
    final subtitleTracks = await _playerService!.getSubtitleTracks();

    if (mounted) {
      setState(() {
        _availableAudioTracks = audioTracks;
        _availableSubtitleTracks = subtitleTracks;
      });
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Detect video format
      final formatDetection = FormatDetectionService();
      _formatResult = await formatDetection.detectFormat(widget.video.path);

      // Initialize VideoPlayerService
      _playerService = vps.VideoPlayerService();
      await _playerService!.initializePlayer(
        videoPath: widget.video.path,
        video: widget.video,
        preferredDecoder:
            _formatResult!.supportsHardwareDecoding && _hardwareAcceleration
                ? vps.DecoderType.hardware
                : vps.DecoderType.software,
        playbackSpeed: _playbackSpeed,
        networkCacheSizeMs: _networkCaching ? _networkCacheSize : null,
      );

      // Load tracks
      await _loadTracks();

      // Load subtitles
      await _loadSubtitles();

      // Subscribe to position and playing state streams
      _positionSubscription =
          _playerService!.positionStream?.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            // Update current subtitle based on position
            if (_subtitlesEnabled) {
              _currentSubtitle = _subtitleService.getSubtitleAt(position);
            } else {
              _currentSubtitle = null;
            }
          });
          _saveLastPosition();

          // Check for auto-play next when video ends
          if (_autoPlayNext && _totalDuration > Duration.zero) {
            final progress =
                position.inMilliseconds / _totalDuration.inMilliseconds;
            if (progress >= 0.99) {
              _handleAutoPlayNext();
            }
          }
        }
      });

      _playingSubscription = _playerService!.playingStream?.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
            // Don't auto-hide controls when video starts playing
            // Controls will only hide when user taps the screen
            // Keep controls visible when paused
            if (!playing) {
              _showControls = true;
            }
          });
        }
      });

      // For VLC player, wait for initialization to complete
      if (_playerService!.currentPlayerType == vps.PlayerType.vlc) {
        final vlcController = _playerService!.vlcController;
        if (vlcController != null) {
          // Listen for VLC initialization
          vlcController.addListener(() {
            if (mounted && vlcController.value.isInitialized) {
              setState(() {
                _totalDuration = vlcController.value.duration;
                if (_totalDuration > Duration.zero) {
                  debugPrint(
                      'VideoPlayerPage: VLC player fully initialized, duration: $_totalDuration');
                }
              });
            }
          });
        }
      }

      // Get initial duration
      _totalDuration = _playerService!.duration;
      if (_totalDuration == Duration.zero) {
        // Wait a bit for duration to be available
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _playerService != null) {
            setState(() => _totalDuration = _playerService!.duration);
          }
        });
      }

      // Apply audio boost after initialization
      await _loadAudioBoost();

      // Initialize volume (with audio boost applied)
      await _playerService!.setVolume(_volume);

      if (widget.resumeFromLastPosition) {
        _loadLastPosition();
      }

      setState(() {
        _isInitialized = true;
        _originalAspectRatio = 16 / 9; // Default, will be updated
        _aspectRatio = _originalAspectRatio;
      });

      _fadeAnimationController.forward();
      _slideAnimationController.forward();

      // Auto-play video after initialization (MX Player style)
      // Wait a bit for BetterPlayer to be fully ready
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted && _playerService != null && _isInitialized) {
          try {
            // Check if BetterPlayer controller is ready
            final betterPlayerController =
                _playerService!.betterPlayerController;
            if (betterPlayerController != null) {
              final videoController =
                  betterPlayerController.videoPlayerController;
              if (videoController != null &&
                  videoController.value.initialized) {
                await _playerService!.togglePlayPause();
                debugPrint(
                    'VideoPlayerPage: Auto-played video after initialization');
              } else {
                // Wait a bit more and try again
                Future.delayed(const Duration(milliseconds: 500), () async {
                  if (mounted && _playerService != null) {
                    final vc = betterPlayerController.videoPlayerController;
                    if (vc != null && vc.value.initialized) {
                      await _playerService!.togglePlayPause();
                      debugPrint(
                          'VideoPlayerPage: Auto-played video after delayed initialization');
                    }
                  }
                });
              }
            }
          } catch (e) {
            debugPrint('VideoPlayerPage: Error auto-playing video: $e');
            // Don't throw - user can manually play
          }
        }
      });

      // Start statistics monitoring
      _startStatisticsMonitoring();
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._initializePlayer');
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getUserFriendlyMessage(e),
          onRetry: () {
            _initializePlayer();
          },
        );
      }
    }
  }

  Future<void> _loadSubtitles() async {
    try {
      // Try to auto-load subtitle file
      final subtitles =
          await _subtitleService.autoLoadForVideo(widget.video.path);
      if (subtitles.isNotEmpty) {
        debugPrint('Loaded ${subtitles.length} subtitles for video');
      }

      // Apply subtitle delay if set
      if (_subtitleDelay != 0.0) {
        _subtitleService.setDelay(_subtitleDelay.toInt());
      }
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._loadSubtitles');
      // Continue without subtitles if loading fails
    }
  }

  void _startStatisticsMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isInitialized && _playerService != null) {
        setState(() {
          // Estimate FPS based on typical video frame rates
          _fps =
              30.0; // Default assumption, can be enhanced with actual detection
          // Get resolution from format result if available
          if (_formatResult != null) {
            // FormatDetectionResult doesn't have width/height, use defaults
            _resolution = '1920x1080'; // Default, can be enhanced
            _bitrate = 1920 * 1080 * _fps / 1000000;
          } else {
            _resolution = 'Unknown';
            _bitrate = 0.0;
          }
          // Buffer duration estimation
          _bufferDuration = _totalDuration > Duration.zero
              ? _totalDuration - _currentPosition
              : Duration.zero;
        });
      }
    });
  }

  Future<void> _loadLastPosition() async {
    try {
      // Try to load from PlaybackPositionService first
      final savedPosition =
          await _playbackPositionService.getPosition(widget.video.path);

      if (savedPosition != null) {
        _lastPosition = savedPosition;
        // Seek to last position
        _playerService?.seekTo(_lastPosition);
      } else if (widget.video.lastPlayedPosition != null) {
        _lastPosition = widget.video.lastPlayedPosition!;
        // Seek to last position
        _playerService?.seekTo(_lastPosition);
      } else {
        _lastPosition = Duration.zero;
      }

      // Save last watched timestamp
      await _playbackPositionService.saveLastWatched(widget.video.path);
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._loadLastPosition');
      // Fallback to video's last position
      if (widget.video.lastPlayedPosition != null) {
        _lastPosition = widget.video.lastPlayedPosition!;
        _playerService?.seekTo(_lastPosition);
      }
    }
  }

  void _saveLastPosition() async {
    try {
      final currentPosition = _currentPosition;
      final totalDuration = _totalDuration;

      // Save to PlaybackPositionService
      await _playbackPositionService.savePosition(
          widget.video.path, currentPosition);
      await _playbackPositionService.saveLastWatched(widget.video.path);

      VideoStatus newStatus = _currentVideo.status;
      if (totalDuration > Duration.zero) {
        final progress =
            currentPosition.inMilliseconds / totalDuration.inMilliseconds;

        if (progress >= 0.9) {
          newStatus = VideoStatus.lastWatched;
        } else if (progress > 0.1) {
          newStatus = VideoStatus.watching;
        } else if (progress > 0) {
          if (_currentVideo.status == VideoStatus.new_) {
            newStatus = VideoStatus.watching;
          }
        }
      }

      final updatedVideo = _currentVideo.copyWith(
        lastPlayedPosition: currentPosition,
        lastPlayedAt: DateTime.now(),
        status: newStatus,
      );

      context.read<VideoListBloc>().add(UpdateVideoStatus(
            videoPath: _currentVideo.path,
            newStatus: newStatus,
            lastPosition: currentPosition,
          ));

      await _saveVideoMetadata(updatedVideo);
      _currentVideo = updatedVideo;
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._saveLastPosition');
      // Continue silently - position saving is not critical
    }
  }

  void _toggleOrientation() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // Auto-hide controls after 5 seconds of inactivity (MX Player style)
    if (_showControls) {
      _controlsHideTimer?.cancel();
      _controlsHideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    } else {
      _controlsHideTimer?.cancel();
    }
  }

  void _resetControlsHideTimer() {
    _controlsHideTimer?.cancel();
    if (_showControls && _isPlaying) {
      _controlsHideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _changeAspectRatio() {
    setState(() {
      _currentAspectRatioIndex =
          (_currentAspectRatioIndex + 1) % (_aspectRatios.length + 1);

      if (_currentAspectRatioIndex == 0) {
        _aspectRatio = _originalAspectRatio;
      } else {
        _aspectRatio = _aspectRatios[_currentAspectRatioIndex - 1];
      }
    });
  }

  void _toggleSubtitles() {
    setState(() {
      _subtitlesEnabled = !_subtitlesEnabled;
    });

    context.read<ThemeBloc>().add(ToggleSubtitles(_subtitlesEnabled));
  }

  void _seekForward() {
    _playerService?.seekRelative(const Duration(seconds: 10));
  }

  void _seekBackward() {
    _playerService?.seekRelative(const Duration(seconds: -10));
  }

  void _openEqualizer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AudioEqualizer(
          gains: _equalizerGains,
          onGainsChanged: (gains) {
            setState(() => _equalizerGains = gains);
            setModalState(() {}); // Rebuild the modal
            // Save gains immediately
            final equalizerService = AudioEqualizerService();
            equalizerService.saveGains(gains);
            // Note: Actual audio equalization would require platform channels
            // or a video player package that supports it (e.g., better_player, VLC)
            // For now, the gains are saved and can be applied when switching players
          },
        ),
      ),
    );
  }

  Future<void> _loadEqualizerPreset() async {
    try {
      final equalizerService = AudioEqualizerService();
      final currentPreset = await equalizerService.getCurrentPreset();
      if (currentPreset != null) {
        final presets = await equalizerService.getPresets();
        final presetGains = presets[currentPreset];
        if (presetGains != null) {
          setState(() {
            _equalizerGains = List.from(presetGains);
          });
        }
      } else {
        // Load saved gains if no preset is selected
        final savedGains = await equalizerService.getGains();
        if (savedGains != null && savedGains.isNotEmpty) {
          setState(() {
            _equalizerGains = List.from(savedGains);
          });
        }
      }
    } catch (e) {
      ErrorHandler.logError(e, context: 'VideoPlayerPage._loadEqualizerPreset');
    }
  }

  void _openVideoEffects() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => VideoEffectsPanel(
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          hue: _hue,
          gamma: _gamma,
          selectedFilter: _selectedFilter,
          rotation: _rotation,
          deinterlace: _deinterlace,
          onBrightnessChanged: (value) {
            setState(() => _brightness = value);
            setModalState(() {}); // Rebuild the modal
          },
          onContrastChanged: (value) {
            setState(() => _contrast = value);
            setModalState(() {}); // Rebuild the modal
          },
          onSaturationChanged: (value) {
            setState(() => _saturation = value);
            setModalState(() {}); // Rebuild the modal
          },
          onHueChanged: (value) {
            setState(() => _hue = value);
            setModalState(() {}); // Rebuild the modal
          },
          onGammaChanged: (value) {
            setState(() => _gamma = value);
            setModalState(() {}); // Rebuild the modal
          },
          onFilterChanged: (filter) {
            setState(() => _selectedFilter = filter);
            setModalState(() {}); // Rebuild the modal
          },
          onRotationChanged: (value) {
            setState(() => _rotation = value);
            setModalState(() {}); // Rebuild the modal
          },
          onDeinterlaceChanged: (value) {
            setState(() => _deinterlace = value);
            setModalState(() {}); // Rebuild the modal
          },
        ),
      ),
    );
  }

  void _openFitModeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VideoFitModeSelector(
        currentFitMode: _videoFitMode,
        onFitModeChanged: (fitMode) {
          setState(() {
            _videoFitMode = fitMode;
          });
          // Update BetterPlayer configuration if initialized
          _updateBetterPlayerFitMode();
          // Save preference
          _saveFitModePreference();
        },
      ),
    );
  }

  void _updateBetterPlayerFitMode() {
    if (_playerService?.betterPlayerController != null && _isInitialized) {
      try {
        // BetterPlayer doesn't support dynamic fit mode changes
        // We need to recreate the controller with new fit mode
        // For now, we'll update it in the widget rendering
        // The fit mode will be applied in _buildPlayerWidget
        debugPrint('VideoPlayerService: Fit mode changed to $_videoFitMode');
      } catch (e) {
        debugPrint('VideoPlayerService: Error updating fit mode: $e');
      }
    }
  }

  Future<void> _saveFitModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('video_fit_mode', _videoFitMode.toString());
    } catch (e) {
      debugPrint('Error saving fit mode preference: $e');
    }
  }

  Future<void> _loadFitModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFitMode = prefs.getString('video_fit_mode');
      if (savedFitMode != null) {
        // Parse BoxFit from string
        final fitModeMap = {
          'BoxFit.contain': BoxFit.contain,
          'BoxFit.cover': BoxFit.cover,
          'BoxFit.fill': BoxFit.fill,
          'BoxFit.fitWidth': BoxFit.fitWidth,
          'BoxFit.fitHeight': BoxFit.fitHeight,
          'BoxFit.none': BoxFit.none,
          'BoxFit.scaleDown': BoxFit.scaleDown,
        };
        if (fitModeMap.containsKey(savedFitMode)) {
          setState(() {
            _videoFitMode = fitModeMap[savedFitMode]!;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading fit mode preference: $e');
    }
  }

  void _openPlaylist() {
    // Get all videos from VideoListBloc to create a playlist
    final videoListState = context.read<VideoListBloc>().state;
    List<VideoFile> playlistVideos = [];
    int currentIndex = 0;

    if (videoListState is VideoListLoaded) {
      playlistVideos = videoListState.videos;
      // Find current video index in the list
      currentIndex =
          playlistVideos.indexWhere((v) => v.path == widget.video.path);
      if (currentIndex == -1) {
        // If current video not in list, add it at the beginning
        playlistVideos = [widget.video, ...playlistVideos];
        currentIndex = 0;
      }
    } else {
      // If no videos loaded, create a playlist with just the current video
      playlistVideos = [widget.video];
      currentIndex = 0;
    }

    if (playlistVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No videos available for playlist')),
      );
      return;
    }

    // Show playlist viewer
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlaylistViewerPage(
        videos: playlistVideos,
        currentIndex: currentIndex,
      ),
    ).then((selectedIndex) {
      if (selectedIndex != null &&
          selectedIndex is int &&
          selectedIndex != currentIndex) {
        // Navigate to selected video
        final selectedVideo = playlistVideos[selectedIndex];
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VideoPlayerPage(
              video: selectedVideo,
              resumeFromLastPosition: true,
            ),
          ),
        );
      }
    });
  }

  void _handleAutoPlayNext() async {
    if (!_autoPlayNext) return;

    // Get all videos from VideoListBloc
    final videoListState = context.read<VideoListBloc>().state;
    if (videoListState is VideoListLoaded) {
      final videos = videoListState.videos;
      final currentIndex =
          videos.indexWhere((v) => v.path == widget.video.path);

      if (currentIndex >= 0) {
        VideoFile? nextVideo;
        if (currentIndex < videos.length - 1) {
          nextVideo = videos[currentIndex + 1];
        } else if (_loopMode == 'All' && videos.isNotEmpty) {
          // Loop back to start
          nextVideo = videos[0];
        }

        if (nextVideo != null) {
          // Navigate to next video
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => VideoPlayerPage(
                  video: nextVideo!,
                  resumeFromLastPosition: _rememberPosition,
                ),
              ),
            );
          }
        }
      }
    }
  }

  void _openChapters() async {
    final chapterService = ChapterService();
    final chapters = await chapterService.detectChapters(widget.video.path);

    if (chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No chapters found in this video'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show chapter navigator
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ChapterNavigator(
        chapters: chapters,
        currentTime: _currentPosition,
        onChapterSelected: (chapterTime) {
          _playerService?.seekTo(chapterTime);
        },
      ),
    );
  }

  void _openAdvancedFeatures() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AdvancedFeaturesPanel(
        hardwareAcceleration: _hardwareAcceleration,
        deinterlace: _deinterlace,
        frameDrop: _frameDrop,
        networkCaching: _networkCaching,
        networkCacheSize: _networkCacheSize,
        audioSync: _audioSync,
        audioDelay: _audioDelay,
        subtitleDelay: _subtitleDelay,
        showTimeRemaining: _showTimeRemaining,
        showBuffering: _showBuffering,
        showQuality: _showQuality,
        rememberPosition: _rememberPosition,
        autoPlayNext: _autoPlayNext,
        shuffleEnabled: _shuffleEnabled,
        selectedQuality: _selectedQuality,
        selectedAudioTrack: _selectedAudioTrack,
        selectedSubtitleTrack: _selectedSubtitleTrack,
        selectedVideoTrack: _selectedVideoTrack,
        backgroundPlayEnabled: _backgroundPlayEnabled,
        loopMode: _loopMode,
        onBackgroundPlayEnabledChanged: (value) {
          setState(() => _backgroundPlayEnabled = value);
          _playerService?.enableBackgroundPlay(value);
          _saveAdvancedFeaturesPreferences();
        },
        onLoopModeChanged: (value) {
          setState(() => _loopMode = value);
          if (value == 'One') {
            _playerService?.setLooping(true);
          } else {
            _playerService?.setLooping(false);
          }
          _saveAdvancedFeaturesPreferences();
        },
        onHardwareAccelerationChanged: (value) async {
          if (_playerService == null || !_isInitialized) {
            setState(() => _hardwareAcceleration = value);
            _saveAdvancedFeaturesPreferences();
            return;
          }

          setState(() {
            _hardwareAcceleration = value;
            _isInitialized = false; // Show loading during switch
          });

          try {
            await _playerService!.switchDecoder(
              value ? vps.DecoderType.hardware : vps.DecoderType.software,
              _networkCacheSize,
            );
            setState(() => _isInitialized = true);
            _advancedFeaturesService.applyHardwareAcceleration(value);
            _saveAdvancedFeaturesPreferences();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Switched to ${value ? "Hardware" : "Software"} decoder'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            ErrorHandler.logError(e,
                context: 'VideoPlayerPage.onHardwareAccelerationChanged');
            setState(() {
              _hardwareAcceleration = !value; // Revert on error
              _isInitialized = true;
            });
            if (mounted) {
              ErrorHandler.showErrorSnackBar(
                context,
                'Failed to switch decoder: ${ErrorHandler.getUserFriendlyMessage(e)}',
              );
            }
          }
        },
        onDeinterlaceChanged: (value) {
          setState(() => _deinterlace = value);
          _saveAdvancedFeaturesPreferences();
        },
        onFrameDropChanged: (value) {
          setState(() => _frameDrop = value);
          _saveAdvancedFeaturesPreferences();
        },
        onNetworkCachingChanged: (value) {
          setState(() => _networkCaching = value);
          _advancedFeaturesService.applyNetworkCaching(
              value, _networkCacheSize);
          _saveAdvancedFeaturesPreferences();
        },
        onNetworkCacheSizeChanged: (value) {
          setState(() => _networkCacheSize = value);
          _advancedFeaturesService.applyNetworkCaching(_networkCaching, value);
          _saveAdvancedFeaturesPreferences();
        },
        onAudioSyncChanged: (value) {
          setState(() => _audioSync = value);
          _saveAdvancedFeaturesPreferences();
        },
        onAudioDelayChanged: (value) async {
          setState(() => _audioDelay = value);
          // Apply audio delay to player if supported
          await _playerService?.setAudioDelay(value.toInt());
          _saveAdvancedFeaturesPreferences();
        },
        onSubtitleDelayChanged: (value) {
          setState(() {
            _subtitleDelay = value;
            _subtitleService.setDelay(value.toInt());
            _subtitleSettings =
                _subtitleSettings.copyWith(delayMs: value.toInt());
          });
          _saveAdvancedFeaturesPreferences();
        },
        onShowTimeRemainingChanged: (value) {
          setState(() => _showTimeRemaining = value);
          _saveAdvancedFeaturesPreferences();
        },
        onShowBufferingChanged: (value) {
          setState(() => _showBuffering = value);
          _saveAdvancedFeaturesPreferences();
        },
        onShowQualityChanged: (value) {
          setState(() => _showQuality = value);
          _saveAdvancedFeaturesPreferences();
        },
        onRememberPositionChanged: (value) {
          setState(() => _rememberPosition = value);
          _saveAdvancedFeaturesPreferences();
        },
        onAutoPlayNextChanged: (value) {
          setState(() => _autoPlayNext = value);
          _saveAdvancedFeaturesPreferences();
        },
        onShuffleEnabledChanged: (value) {
          setState(() => _shuffleEnabled = value);
          _saveAdvancedFeaturesPreferences();
        },
        ambientModeEnabled: _ambientModeEnabled,
        onAmbientModeChanged: (value) =>
            setState(() => _ambientModeEnabled = value),
        onQualityChanged: (value) {
          setState(() => _selectedQuality = value);
          _saveAdvancedFeaturesPreferences();
        },
        onAudioTrackChanged: (value) async {
          setState(() => _selectedAudioTrack = value);
          // Convert track name to index and set it
          final tracks = await _playerService?.getAudioTracks() ?? ['Default'];
          final trackIndex = tracks.indexOf(value);
          if (trackIndex >= 0) {
            await _playerService?.setAudioTrack(trackIndex);
          }
          _saveAdvancedFeaturesPreferences();
        },
        onSubtitleTrackChanged: (value) async {
          setState(() => _selectedSubtitleTrack = value);
          // Convert track name to index and set it
          if (value != 'None' && _playerService != null) {
            final tracks = await _playerService!.getSubtitleTracks();
            final trackIndex = tracks.indexOf(value);
            if (trackIndex >= 0) {
              await _playerService!.setSubtitleTrack(trackIndex);
            }
          }
          _saveAdvancedFeaturesPreferences();
        },
        onVideoTrackChanged: (value) async {
          setState(() => _selectedVideoTrack = value);
          // Convert track name to index and set it
          if (_playerService != null) {
            final tracks = await _playerService!.getVideoTracks();
            final trackIndex = tracks.indexOf(value);
            if (trackIndex >= 0) {
              await _playerService!.setVideoTrack(trackIndex);
            }
          }
          _saveAdvancedFeaturesPreferences();
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_playerService == null || !_isInitialized || !mounted) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Default to loading to ensure assignment
    Widget playerWidget = const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );

    final playerType = _playerService!.currentPlayerType;

    switch (playerType) {
      case vps.PlayerType.betterPlayer:
        final controller = _playerService?.betterPlayerController;
        if (controller != null) {
          try {
            // Check if the underlying video controller is still valid and not disposed
            final videoController = controller.videoPlayerController;
            if (videoController != null &&
                videoController.value.initialized &&
                !videoController.value.hasError) {
              // BetterPlayer needs bounded constraints - use SizedBox.expand to fill available space
              // BetterPlayer controls are disabled in configuration, so only video is shown
              // Use a stable key to prevent unnecessary rebuilds that interrupt playback
              playerWidget = SizedBox.expand(
                child: BetterPlayer(
                  controller: controller,
                  key: const ValueKey(
                      'better_player'), // Stable key to prevent playback interruption
                ),
              );
            }
          } catch (e) {
            // Controller might be disposed, show loading indicator
            debugPrint(
                'VideoPlayerPage: Error building BetterPlayer widget: $e');
          }
        }
        break;
      case vps.PlayerType.vlc:
        final controller = _playerService?.vlcController;
        if (controller != null) {
          // Build VlcPlayer widget - it will handle initialization
          // Wrap in Builder to ensure widget tree is ready
          // Use a unique key to force rebuild if needed
          playerWidget = Builder(
            builder: (context) {
              // Use a small delay to ensure native view is ready
              return FutureBuilder<bool>(
                future: Future.delayed(
                    const Duration(milliseconds: 100), () => true),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    try {
                      return VlcPlayer(
                        controller: controller,
                        aspectRatio: _aspectRatio,
                        placeholder: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.black, Colors.grey[900]!],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 3),
                          ),
                        ),
                      );
                    } catch (e) {
                      // If initialization fails, show error placeholder
                      debugPrint('VideoPlayerPage: VlcPlayer build error: $e');
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.black, Colors.grey[900]!],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.white, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Failed to initialize VLC player',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error: $e',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                  // Show loading while waiting
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.black, Colors.grey[900]!],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3),
                    ),
                  );
                },
              );
            },
          );
        } else {
          playerWidget = Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.black, Colors.grey[900]!],
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 3),
            ),
          );
        }
        break;
      case vps.PlayerType.videoPlayer:
        playerWidget = const Center(
          child: Text(
            'Video player fallback not implemented',
            style: TextStyle(color: Colors.white),
          ),
        );
        break;
    }

    Widget finalWidget = playerWidget;

    // Apply rotation if any
    if (_rotation != 0.0) {
      finalWidget = Transform.rotate(
        angle: _rotation * 3.14159 / 180.0, // Convert degrees to radians
        child: finalWidget,
      );
    }

    // Apply video effects (color filters) if any
    if (_brightness != 1.0 ||
        _contrast != 1.0 ||
        _saturation != 1.0 ||
        _hue != 0.0 ||
        _gamma != 1.0) {
      finalWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(_createCombinedColorMatrix()),
        child: finalWidget,
      );
    }

    // Apply aspect ratio
    // BetterPlayer handles its own fit mode via configuration
    // We just need to provide proper constraints
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: finalWidget,
    );
  }

  List<double> _createCombinedColorMatrix() {
    // Start with identity matrix
    List<double> matrix = [
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    // Apply brightness and contrast
    if (_brightness != 1.0 || _contrast != 1.0) {
      final brightnessOffset = (_brightness - 1.0) * 255.0;
      matrix[0] = _contrast;
      matrix[6] = _contrast;
      matrix[12] = _contrast;
      matrix[4] = brightnessOffset;
      matrix[9] = brightnessOffset;
      matrix[14] = brightnessOffset;
    }

    // Apply saturation
    if (_saturation != 1.0) {
      final luminanceR = 0.213;
      final luminanceG = 0.715;
      final luminanceB = 0.072;

      final newMatrix = [
        (1.0 - _saturation) * luminanceR + _saturation,
        (1.0 - _saturation) * luminanceR,
        (1.0 - _saturation) * luminanceR,
        0.0,
        0.0,
        (1.0 - _saturation) * luminanceG,
        (1.0 - _saturation) * luminanceG + _saturation,
        (1.0 - _saturation) * luminanceG,
        0.0,
        0.0,
        (1.0 - _saturation) * luminanceB,
        (1.0 - _saturation) * luminanceB,
        (1.0 - _saturation) * luminanceB + _saturation,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ];

      // Multiply matrices (simplified - just apply saturation)
      matrix = newMatrix;
    }

    // Apply hue rotation (simplified)
    if (_hue != 0.0) {
      // For hue rotation, we'll use a simplified approach
      // This provides basic hue shifting functionality
      final hueRadians = _hue * 3.14159 / 180.0;
      final cosHue = (hueRadians == 0)
          ? 1.0
          : (hueRadians == 3.14159)
              ? -1.0
              : (hueRadians == 1.5708)
                  ? 0.0
                  : (hueRadians == 4.7124)
                      ? 0.0
                      : (1.0 + hueRadians / 3.14159) * 0.5;
      final sinHue = (hueRadians == 0)
          ? 0.0
          : (hueRadians == 3.14159)
              ? 0.0
              : (hueRadians == 1.5708)
                  ? 1.0
                  : (hueRadians == 4.7124)
                      ? -1.0
                      : (1.0 - hueRadians / 3.14159) * 0.5;

      final hueMatrix = [
        0.213 + cosHue * 0.787 - sinHue * 0.213,
        0.213 - cosHue * 0.213 + sinHue * 0.143,
        0.213 - cosHue * 0.213 - sinHue * 0.787,
        0.0,
        0.0,
        0.715 - cosHue * 0.715 - sinHue * 0.715,
        0.715 + cosHue * 0.285 + sinHue * 0.140,
        0.715 - cosHue * 0.715 + sinHue * 0.715,
        0.0,
        0.0,
        0.072 - cosHue * 0.072 + sinHue * 0.072,
        0.072 - cosHue * 0.072 - sinHue * 0.283,
        0.072 + cosHue * 0.928 + sinHue * 0.072,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ];

      // Apply hue matrix (simplified multiplication)
      matrix = hueMatrix;
    }

    // Apply gamma correction (simplified)
    if (_gamma != 1.0) {
      final gammaCorrection = 1.0 / _gamma;
      matrix[0] *= gammaCorrection;
      matrix[6] *= gammaCorrection;
      matrix[12] *= gammaCorrection;
    }

    return matrix;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Future<bool> _onWillPop() async {
    if (_isFullScreen) {
      _toggleOrientation();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _saveLastPosition();
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _controlsHideTimer?.cancel();
    _playerService?.dispose();
    _playerService = null; // Clear reference to prevent use after disposal
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();

    super.dispose();
  }

  // Gesture Handling Methods
  void _togglePlayPause() {
    if (_isPlaying) {
      _playerService?.pause();
    } else {
      _playerService?.play();
    }
  }

  void _handleSubtitleToggle(bool enabled) {
    if (_subtitlesEnabled != enabled) {
      _toggleSubtitles();
    }
  }

  // State for unified internal gesture handling
  String? _currentGestureMode; // 'zoom', 'seek', 'volume', 'brightness', null
  double _initialScale = 1.0;
  double _initialVolume = 1.0;
  double _initialBrightness = 1.0;

  void _handleScaleStart(ScaleStartDetails details) {
    if (!_isInitialized || _isLocked) return;

    setState(() {
      _isDragging = true;
      _currentGestureMode = null; // Decided moving forward based on delta/scale
      _initialScale = _videoScale;
      _initialVolume = _volume;
      _initialBrightness = _brightness;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!_isInitialized || _isLocked) return;

    // Detect Mode if not yet set
    if (_currentGestureMode == null) {
      if ((details.scale - 1.0).abs() > 0.1) {
        // Significant scaling -> Zoom
        setState(() {
          _currentGestureMode = 'zoom';
          _dragType = 'Zoom';
          _dragIcon = Icons.zoom_in;
        });
      } else if (details.focalPointDelta.distance > 5.0) {
        // Significant movement -> Pan (Seek/Vol/Bright)
        final dx = details.focalPointDelta.dx.abs();
        final dy = details.focalPointDelta.dy.abs();
        if (dx > dy) {
          setState(() {
            _currentGestureMode = 'seek';
            _dragType = 'Seek';
            _dragTargetTime = _currentPosition; // Init seek-from point
          });
        } else {
          final screenWidth = MediaQuery.of(context).size.width;
          final isRightSide = details.focalPoint.dx > screenWidth / 2;
          setState(() {
            _currentGestureMode = isRightSide ? 'volume' : 'brightness';
            _dragType = isRightSide ? 'Volume' : 'Brightness';
            _dragValue = isRightSide ? _initialVolume : _initialBrightness;
          });
        }
      }
    }

    // Handle Active Mode
    if (_currentGestureMode == 'zoom') {
      setState(() {
        _videoScale = (_initialScale * details.scale).clamp(0.5, 4.0);
        _dragLabel = '${(_videoScale * 100).toInt()}%';
        _dragIcon = _videoScale > 1.0 ? Icons.zoom_in : Icons.zoom_out;
      });
    } else if (_currentGestureMode == 'seek') {
      // Seek Logic
      // Sensitivity: 1px = 200ms
      const double sensitivity = 200.0;
      final deltaMs = details.focalPointDelta.dx * sensitivity;
      if (deltaMs != 0) {
        final newPos =
            _dragTargetTime + Duration(milliseconds: deltaMs.toInt());
        setState(() {
          _dragTargetTime =
              _clampDuration(newPos, Duration.zero, _totalDuration);
          _dragLabel =
              '${_formatDuration(_dragTargetTime)} / ${_formatDuration(_totalDuration)}';
          _dragIcon = deltaMs > 0 ? Icons.fast_forward : Icons.fast_rewind;
        });
      }
    } else if (_currentGestureMode == 'volume') {
      // Volume Logic (dy negative is up)
      final delta = -(details.focalPointDelta.dy /
          MediaQuery.of(context).size.height); // Normalize
      final newValue =
          (_initialVolume + delta * 2.0).clamp(0.0, 1.0); // *2.0 sensitivity
      _playerService?.setVolume(newValue);
      setState(() {
        _volume = newValue;
        _dragValue = newValue;
        _dragLabel = '${(_dragValue * 100).toInt()}%';
        _dragIcon = _volume == 0 ? Icons.volume_off : Icons.volume_up;
      });
    } else if (_currentGestureMode == 'brightness') {
      // Brightness Logic
      final delta =
          -(details.focalPointDelta.dy / MediaQuery.of(context).size.height);
      final newValue = (_initialBrightness + delta * 2.0).clamp(0.0, 1.0);
      setState(() {
        _brightness = newValue;
        _dragValue = newValue;
        _dragLabel = '${(_dragValue * 100).toInt()}%';
        _dragIcon = Icons.brightness_6;
      });
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!_isInitialized || _isLocked) return;

    if (_currentGestureMode == 'seek') {
      _playerService?.seekTo(_dragTargetTime);
    }

    // Reset state
    setState(() {
      _isDragging = false;
      _dragType = null;
      _currentGestureMode = null;
    });
  }

  Duration _clampDuration(Duration duration, Duration min, Duration max) {
    if (duration < min) return min;
    if (duration > max) return max;
    return duration;
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _showControls = false; // Hide controls immediately when locking
        _isDragging = false; // Cancel any active drag
      } else {
        _showControls = true; // Show controls when unlocking
        _resetControlsHideTimer();
      }
    });

    if (_isLocked) {
      _showTempOverlay(Icons.lock, 'Locked');
    } else {
      _showTempOverlay(Icons.lock_open, 'Unlocked');
    }
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    if (_isLocked) {
      // Create a visual hint that it's locked, or just ignore
      _showTempOverlay(Icons.lock, 'Locked');
      _showControls = true; // Show just the lock button (handled in build)
      _resetControlsHideTimer();
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final tapPosition = details.globalPosition.dx;

    if (tapPosition < screenWidth / 3) {
      // Left third: Seek backward 10s
      _seekBackward();
      _showTempOverlay(Icons.replay_10, '-10s');
    } else if (tapPosition > (screenWidth * 2 / 3)) {
      // Right third: Seek forward 10s
      _seekForward();
      _showTempOverlay(Icons.forward_10, '+10s');
    } else {
      // Center: Toggle Play/Pause
      _togglePlayPause();
      _showTempOverlay(
        _isPlaying ? Icons.pause : Icons.play_arrow,
        _isPlaying ? 'Pause' : 'Play',
      );
    }
  }

  // Temporary overlay for double tap feedback
  void _showTempOverlay(IconData icon, String text) {
    setState(() {
      _isDragging = true; // Use same overlay mechanism
      _dragType = 'Feedback';
      _dragIcon = icon;
      _dragLabel = text;
    });

    // Auto hide after short delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _dragType == 'Feedback') {
        setState(() {
          _isDragging = false;
          _dragType = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LastPlayedBloc.create(),
      child: BlocListener<LastPlayedBloc, LastPlayedState>(
        listener: (context, state) {
          if (_isPlaying && state is! LastPlayedLoaded) {
            context
                .read<LastPlayedBloc>()
                .add(SetLastPlayedVideo(widget.video));
          }
        },
        child: WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: Colors.black,
            // AppBar removed to prevents duplication with FloatingVideoControls
            body: Stack(
              children: [
                // Ambient Mode Background
                if (_ambientModeEnabled && _isInitialized)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.6,
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Transform.scale(
                          scale: 1.2,
                          child: _buildVideoPlayer(),
                        ),
                      ),
                    ),
                  ),

                // Video player - use Positioned.fill to ensure bounded constraints
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Center(
                      child: _isInitialized && _playerService != null
                          ? Transform.scale(
                              scale: _videoScale,
                              child: _buildVideoPlayer(),
                            )
                          : const CircularProgressIndicator(
                              color: Colors.white),
                    ),
                  ),
                ),

                // Comprehensive Gesture Detector (MX Player Style)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (_isLocked) {
                        // Briefly show controls (which will only show the unlock button)
                        setState(() => _showControls = !_showControls);
                        if (_showControls) _resetControlsHideTimer();
                      } else {
                        _toggleControls();
                      }
                    },
                    onDoubleTapDown: _handleDoubleTapDown,
                    // Unified Gesture Handling (Scale + Pan)
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onScaleEnd: _handleScaleEnd,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      color: Colors.transparent,
                      // Gesture Feedback Overlay
                      child: _isDragging
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_dragIcon != null)
                                      Icon(_dragIcon,
                                          color: Colors.white, size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      _dragLabel ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (_dragType == 'Seek')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '[${(_dragTargetTime - _currentPosition).isNegative ? '' : '+'}${_formatDuration(_dragTargetTime - _currentPosition)}]',
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),

                // Large center play button overlay (MX Player style)
                // Always visible when paused, even if controls are hidden
                if (!_isPlaying && _isInitialized && !_isLocked && !_isDragging)
                  Center(
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),

                // Subtitle overlay
                if (_subtitlesEnabled && _currentSubtitle != null)
                  SubtitleOverlay(
                    currentSubtitle: _currentSubtitle,
                    settings: _subtitleSettings.copyWith(
                      delayMs: _subtitleDelay.toInt(),
                    ),
                    onPositionChanged: (position) {
                      setState(() {
                        _subtitleSettings = _subtitleSettings.copyWith(
                          position: position,
                        );
                      });
                    },
                    onFontSizeChanged: (fontSize) {
                      setState(() {
                        _subtitleSettings = _subtitleSettings.copyWith(
                          fontSize: fontSize,
                        );
                      });
                    },
                    onTap: _toggleControls,
                  ),

                // Advanced features floating controls overlay (top controls)
                // Advanced Controls Overlay (Top) - Only when unlocked
                if (_showControls && !_isLocked)
                  Positioned.fill(
                    child: FloatingVideoControls(
                      position: _currentPosition,
                      duration: _totalDuration,
                      isPlaying: _isPlaying,
                      showControls: _showControls,
                      onTogglePlayPause: _togglePlayPause,
                      onOpenEqualizer: _openEqualizer,
                      onOpenVideoEffects: _openVideoEffects,
                      hasVideoEffects: false, // Placeholder
                      onOpenAdvancedFeatures: _openAdvancedFeatures,
                      onOpenFitModeSelector: _openFitModeSelector,
                      onSeekForward: _seekForward,
                      onSeekBackward: _seekBackward,
                      onToggleStatistics: () {
                        setState(() {
                          _showStatistics = !_showStatistics;
                        });
                      },
                      onOpenPlaylist: _openPlaylist,
                      onOpenChapters: _openChapters,
                      onPlaybackSpeedChanged: (speed) {
                        setState(() {
                          _playbackSpeed = speed;
                          _playerService?.setPlaybackSpeed(speed);
                        });
                      },
                      playbackSpeed: _playbackSpeed,
                      showStatistics: _showStatistics,
                      hardwareAcceleration: _hardwareAcceleration,
                      deinterlace: _deinterlace,
                      frameDrop: _frameDrop,
                      networkCaching: _networkCaching,
                      networkCacheSize: _networkCacheSize,
                      audioSync: _audioSync,
                      audioDelay: _audioDelay,
                      subtitleDelay: _subtitleDelay,
                      showTimeRemaining: _showTimeRemaining,
                      showBuffering: _showBuffering,
                      showQuality: _showQuality,
                      rememberPosition: _rememberPosition,
                      autoPlayNext: _autoPlayNext,
                      shuffleEnabled: _shuffleEnabled,
                      selectedQuality: _selectedQuality,
                      selectedAudioTrack: _selectedAudioTrack,
                      selectedSubtitleTrack: _selectedSubtitleTrack,
                      selectedVideoTrack: _selectedVideoTrack,
                      backgroundPlayEnabled: _backgroundPlayEnabled,
                      loopMode: _loopMode,
                      availableAudioTracks: _availableAudioTracks,
                      availableSubtitleTracks: _availableSubtitleTracks,
                      ambientModeEnabled: _ambientModeEnabled,
                      onAmbientModeChanged: (value) =>
                          setState(() => _ambientModeEnabled = value),
                      onHardwareAccelerationChanged: (value) async {
                        setState(() {
                          _hardwareAcceleration = value;
                          _isInitialized = false;
                        });
                        try {
                          await _playerService!.switchDecoder(
                            value
                                ? vps.DecoderType.hardware
                                : vps.DecoderType.software,
                          );
                          setState(() => _isInitialized = true);
                          _saveAdvancedFeaturesPreferences();
                        } catch (e) {
                          setState(() {
                            _hardwareAcceleration = !value;
                            _isInitialized = true;
                          });
                        }
                      },
                      onDeinterlaceChanged: (value) =>
                          setState(() => _deinterlace = value),
                      onFrameDropChanged: (value) =>
                          setState(() => _frameDrop = value),
                      onNetworkCachingChanged: (value) =>
                          setState(() => _networkCaching = value),
                      onNetworkCacheSizeChanged: (value) =>
                          setState(() => _networkCacheSize = value),
                      onAudioSyncChanged: (value) =>
                          setState(() => _audioSync = value),
                      onAudioDelayChanged: (value) async {
                        setState(() => _audioDelay = value);
                        await _playerService?.setAudioDelay(value.toInt());
                        _saveAdvancedFeaturesPreferences();
                      },
                      onSubtitleDelayChanged: (value) {
                        setState(() {
                          _subtitleDelay = value;
                          _subtitleService.setDelay(value.toInt());
                        });
                      },
                      onShowTimeRemainingChanged: (value) =>
                          setState(() => _showTimeRemaining = value),
                      onShowBufferingChanged: (value) =>
                          setState(() => _showBuffering = value),
                      onShowQualityChanged: (value) =>
                          setState(() => _showQuality = value),
                      onRememberPositionChanged: (value) =>
                          setState(() => _rememberPosition = value),
                      onAutoPlayNextChanged: (value) =>
                          setState(() => _autoPlayNext = value),
                      onShuffleEnabledChanged: (value) =>
                          setState(() => _shuffleEnabled = value),
                      onQualityChanged: (value) =>
                          setState(() => _selectedQuality = value),
                      onAudioTrackChanged: (value) async {
                        setState(() => _selectedAudioTrack = value);
                        final tracks = await _playerService?.getAudioTracks() ??
                            ['Default'];
                        final trackIndex = tracks.indexOf(value);
                        if (trackIndex >= 0) {
                          await _playerService?.setAudioTrack(trackIndex);
                        }
                        _saveAdvancedFeaturesPreferences();
                      },
                      onSubtitleTrackChanged: (value) async {
                        setState(() => _selectedSubtitleTrack = value);
                        if (value != 'None' && _playerService != null) {
                          final tracks =
                              await _playerService!.getSubtitleTracks();
                          final trackIndex = tracks.indexOf(value);
                          if (trackIndex >= 0) {
                            await _playerService!.setSubtitleTrack(trackIndex);
                          }
                        }
                        _saveAdvancedFeaturesPreferences();
                      },
                      onVideoTrackChanged: (value) async {
                        setState(() => _selectedVideoTrack = value);
                        if (_playerService != null) {
                          final tracks = await _playerService!.getVideoTracks();
                          final trackIndex = tracks.indexOf(value);
                          if (trackIndex >= 0) {
                            await _playerService!.setVideoTrack(trackIndex);
                          }
                        }
                        _saveAdvancedFeaturesPreferences();
                      },
                      onBackgroundPlayEnabledChanged: (value) async {
                        setState(() => _backgroundPlayEnabled = value);
                        _playerService?.enableBackgroundPlay(value);
                        _saveAdvancedFeaturesPreferences();
                      },
                      onLoopModeChanged: (value) async {
                        setState(() => _loopMode = value);
                        await _playerService?.setLooping(value == 'One');
                        _saveAdvancedFeaturesPreferences();
                      },
                    ),
                  ),

                // Bottom Controls (MX Player Style) - Only when unlocked
                if (_showControls && !_isLocked)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showControls,
                        child: RepaintBoundary(
                          child: MxPlayerControls(
                            position: _currentPosition,
                            duration: _totalDuration,
                            isPlaying: _isPlaying,
                            volume: _volume,
                            audioBoost: _audioBoost,
                            brightness: _brightness,
                            playbackSpeed: _playbackSpeed,
                            subtitlesEnabled: _subtitlesEnabled,
                            selectedAudioTrack: _selectedAudioTrack,
                            selectedSubtitleTrack: _selectedSubtitleTrack,
                            onTogglePlayPause: _togglePlayPause,
                            onSeek: (pos) => _playerService?.seekTo(pos),
                            onVolumeChanged: (vol) =>
                                _playerService?.setVolume(vol),
                            onAudioBoostChanged: (boost) =>
                                _applyAudioBoost(boost),
                            onBrightnessChanged: (val) =>
                                setState(() => _brightness = val),
                            onPlaybackSpeedChanged: (speed) =>
                                _playerService?.setPlaybackSpeed(speed),
                            onSubtitlesToggled: _handleSubtitleToggle,
                            onAudioTrackChanged: (track) async {
                              setState(() => _selectedAudioTrack = track);
                              final tracks =
                                  await _playerService?.getAudioTracks() ??
                                      ['Default'];
                              final trackIndex = tracks.indexOf(track);
                              if (trackIndex >= 0) {
                                await _playerService?.setAudioTrack(trackIndex);
                              }
                              _saveAdvancedFeaturesPreferences();
                            },
                            onSubtitleTrackChanged: (track) async {
                              setState(() => _selectedSubtitleTrack = track);
                              if (track != 'None' && _playerService != null) {
                                final tracks =
                                    await _playerService!.getSubtitleTracks();
                                final trackIndex = tracks.indexOf(track);
                                if (trackIndex >= 0) {
                                  await _playerService!
                                      .setSubtitleTrack(trackIndex);
                                }
                              }
                              _saveAdvancedFeaturesPreferences();
                            },
                            onLockToggle: _toggleLock,
                            onToggleFit: _changeAspectRatio,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Unlock Overlay - Only when locked and tapped
                if (_showControls && _isLocked)
                  Positioned(
                    top: 50,
                    left: 20,
                    child: SafeArea(
                      child: GestureDetector(
                        onTap: _toggleLock,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock_open,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text('Unlock',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Statistics overlay
                if (_showStatistics) _buildStatisticsOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsOverlay() {
    return Positioned(
      top: 100,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Statistics',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  onPressed: () => setState(() => _showStatistics = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('FPS: ${_fps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('Bitrate: ${_bitrate.toStringAsFixed(1)} Mbps',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('Resolution: $_resolution',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('Buffer: ${_bufferDuration.inSeconds}s',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('Speed: ${_playbackSpeed}x',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text('Volume: ${(_volume * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
