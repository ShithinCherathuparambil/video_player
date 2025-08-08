import 'dart:io';
import 'dart:async'; // Added for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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
import 'package:lumeo/presentation/widgets/audio_equalizer.dart';
import 'package:lumeo/presentation/widgets/video_effects_panel.dart';
import 'package:lumeo/presentation/widgets/advanced_features_panel.dart';
import 'package:lumeo/presentation/widgets/floating_video_controls.dart';

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
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isFullScreen = false;
  bool _isPlaying = false;
  bool _showControls = true;

  Duration _lastPosition = Duration.zero;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late SaveVideoMetadata _saveVideoMetadata;
  late VideoFile _currentVideo;

  // Video Controls
  bool _subtitlesEnabled = true;
  bool _audioEnabled = true;
  double _volume = 1.0;
  double _playbackSpeed = 1.0;
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

  // Playback controls
  bool _loopEnabled = false;
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

  // Advanced features
  String _selectedQuality = 'Auto';
  String _selectedAudioTrack = 'Default';
  String _selectedSubtitleTrack = 'None';
  String _selectedVideoTrack = 'Default';

  // UI State
  bool _showPlaylist = false;
  bool _showEqualizer = false;
  bool _showStatistics = false;
  bool _showChapters = false;
  bool _showAudioTracks = false;
  bool _showSubtitleTracks = false;
  bool _showVideoTracks = false;

  // Playback statistics
  double _fps = 0.0;
  double _bitrate = 0.0;
  String _codec = '';
  String _resolution = '';
  Duration _bufferDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _initializeDependencies();
    _initializeAnimations();
    _initializePlayer();

    // Load preferences from theme bloc
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeState = context.read<ThemeBloc>().state;
      if (themeState is ThemeLoaded) {
        setState(() {
          _subtitlesEnabled = themeState.subtitlesEnabled;
        });
      }
    });
  }

  void _initializeDependencies() {
    final videoRepository = VideoRepositoryImpl(
      localDataSource: VideoLocalDataSourceImpl(),
    );
    _saveVideoMetadata = SaveVideoMetadata(videoRepository);
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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController =
        VideoPlayerController.file(File(widget.video.path));
    await _videoPlayerController.initialize();

    setState(() {
      _originalAspectRatio = _videoPlayerController.value.aspectRatio;
      _aspectRatio = _originalAspectRatio;
    });

    if (widget.resumeFromLastPosition) {
      _loadLastPosition();
    }

    _createChewieController();
    _fadeAnimationController.forward();
    _slideAnimationController.forward();

    // Start statistics monitoring
    _startStatisticsMonitoring();
  }

  void _startStatisticsMonitoring() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _videoPlayerController.value.isInitialized) {
        setState(() {
          // Estimate FPS based on typical video frame rates
          _fps =
              30.0; // Default assumption, can be enhanced with actual detection
          _bitrate = _videoPlayerController.value.size.width *
              _videoPlayerController.value.size.height *
              _fps /
              1000000;
          _resolution =
              '${_videoPlayerController.value.size.width.toInt()}x${_videoPlayerController.value.size.height.toInt()}';
          _bufferDuration = _videoPlayerController.value.buffered.isNotEmpty
              ? _videoPlayerController.value.buffered.first.end -
                  _videoPlayerController.value.position
              : Duration.zero;
        });
      }
    });
  }

  void _loadLastPosition() {
    if (widget.video.lastPlayedPosition != null) {
      _lastPosition = widget.video.lastPlayedPosition!;
    } else {
      _lastPosition = const Duration(seconds: 30);
    }
  }

  void _saveLastPosition() async {
    try {
      final currentPosition = _videoPlayerController.value.position;
      final totalDuration = _videoPlayerController.value.duration;

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
      // Handle error silently
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: _loopEnabled,
      aspectRatio: _aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      showOptions: false,
      subtitle: _subtitlesEnabled ? Subtitles([]) : null,
      placeholder: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.grey[900]!],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      ),
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        handleColor: Theme.of(context).colorScheme.primary,
        backgroundColor:
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        bufferedColor: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
      ),
      customControls: const MaterialControls(),
      errorBuilder: (context, errorMessage) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.red[900]!, Colors.red[700]!],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Playback Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    _videoPlayerController.addListener(_onPlayerStateChanged);

    if (widget.resumeFromLastPosition && _lastPosition > Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _videoPlayerController.seekTo(_lastPosition);
      });
    }

    setState(() {});
  }

  void _onPlayerStateChanged() {
    final isPlaying = _videoPlayerController.value.isPlaying;
    if (isPlaying != _isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
        if (isPlaying) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _videoPlayerController.value.isPlaying) {
              setState(() {
                _showControls = false;
              });
            }
          });
        } else {
          _showControls = true;
        }
      });
    }

    if (isPlaying) {
      _saveLastPosition();
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

      if (_chewieController != null) {
        _chewieController!.dispose();
        _createChewieController();
      }
    });
  }

  void _changePlaybackSpeed() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentIndex = speeds.indexOf(_playbackSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;

    setState(() {
      _playbackSpeed = speeds[nextIndex];
    });

    _videoPlayerController.setPlaybackSpeed(_playbackSpeed);
  }

  void _toggleSubtitles() {
    setState(() {
      _subtitlesEnabled = !_subtitlesEnabled;
    });

    if (_chewieController != null) {
      _chewieController!.dispose();
      _createChewieController();
    }

    context.read<ThemeBloc>().add(ToggleSubtitles(_subtitlesEnabled));
  }

  void _toggleAudio() {
    setState(() {
      _audioEnabled = !_audioEnabled;
    });

    if (_audioEnabled) {
      _videoPlayerController.setVolume(_volume);
    } else {
      _videoPlayerController.setVolume(0.0);
    }
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
    });

    if (_audioEnabled) {
      _videoPlayerController.setVolume(_volume);
    }
  }

  void _toggleLoop() {
    setState(() {
      _loopEnabled = !_loopEnabled;
    });

    if (_chewieController != null) {
      _chewieController!.dispose();
      _createChewieController();
    }
  }

  void _seekForward() {
    final currentPosition = _videoPlayerController.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    _videoPlayerController.seekTo(newPosition);
  }

  void _seekBackward() {
    final currentPosition = _videoPlayerController.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _videoPlayerController.seekTo(newPosition);
  }

  void _seekToPercentage(double percentage) {
    final totalDuration = _videoPlayerController.value.duration;
    final targetPosition = totalDuration * percentage;
    _videoPlayerController.seekTo(targetPosition);
  }

  void _openEqualizer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AudioEqualizer(
        gains: _equalizerGains,
        onGainsChanged: (gains) {
          setState(() {
            _equalizerGains = gains;
          });
        },
      ),
    );
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
        ),
      ),
    );
  }

  void _openPlaylist() {
    // TODO: Implement playlist functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playlist feature coming soon!')),
    );
  }

  void _openChapters() {
    // TODO: Implement chapters functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chapters feature coming soon!')),
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
        onHardwareAccelerationChanged: (value) =>
            setState(() => _hardwareAcceleration = value),
        onDeinterlaceChanged: (value) => setState(() => _deinterlace = value),
        onFrameDropChanged: (value) => setState(() => _frameDrop = value),
        onNetworkCachingChanged: (value) =>
            setState(() => _networkCaching = value),
        onNetworkCacheSizeChanged: (value) =>
            setState(() => _networkCacheSize = value),
        onAudioSyncChanged: (value) => setState(() => _audioSync = value),
        onAudioDelayChanged: (value) => setState(() => _audioDelay = value),
        onSubtitleDelayChanged: (value) =>
            setState(() => _subtitleDelay = value),
        onShowTimeRemainingChanged: (value) =>
            setState(() => _showTimeRemaining = value),
        onShowBufferingChanged: (value) =>
            setState(() => _showBuffering = value),
        onShowQualityChanged: (value) => setState(() => _showQuality = value),
        onRememberPositionChanged: (value) =>
            setState(() => _rememberPosition = value),
        onAutoPlayNextChanged: (value) => setState(() => _autoPlayNext = value),
        onShuffleEnabledChanged: (value) =>
            setState(() => _shuffleEnabled = value),
        onQualityChanged: (value) => setState(() => _selectedQuality = value),
        onAudioTrackChanged: (value) =>
            setState(() => _selectedAudioTrack = value),
        onSubtitleTrackChanged: (value) =>
            setState(() => _selectedSubtitleTrack = value),
        onVideoTrackChanged: (value) =>
            setState(() => _selectedVideoTrack = value),
      ),
    );
  }

  String _getAspectRatioLabel() {
    switch (_currentAspectRatioIndex) {
      case 0:
        return _formatAspectRatio(_originalAspectRatio);
      case 1:
        return '16:9';
      case 2:
        return '4:3';
      case 3:
        return '1:1';
      case 4:
        return '21:9';
      case 5:
        return '2.35:1';
      default:
        return _formatAspectRatio(_originalAspectRatio);
    }
  }

  String _formatAspectRatio(double ratio) {
    final roundedRatio = (ratio * 100).round() / 100;

    if ((ratio - 16 / 9).abs() < 0.01) return '16:9';
    if ((ratio - 4 / 3).abs() < 0.01) return '4:3';
    if ((ratio - 1 / 1).abs() < 0.01) return '1:1';
    if ((ratio - 21 / 9).abs() < 0.01) return '21:9';
    if ((ratio - 2.35 / 1).abs() < 0.01) return '2.35:1';

    return '${roundedRatio.toStringAsFixed(2)}:1';
  }

  Widget _buildVideoWithEffects() {
    // Check if any effects are applied
    final hasEffects = _brightness != 1.0 ||
        _contrast != 1.0 ||
        _saturation != 1.0 ||
        _hue != 0.0 ||
        _gamma != 1.0;

    if (!hasEffects) {
      return Chewie(controller: _chewieController!);
    }

    // Create a combined color filter matrix for all effects
    final matrix = _createCombinedColorMatrix();

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: Chewie(controller: _chewieController!),
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
    _videoPlayerController.removeListener(_onPlayerStateChanged);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();

    super.dispose();
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
            appBar: _isFullScreen ? null : _buildAppBar(),
            body: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // Video player
                  Center(
                    child: _chewieController != null
                        ? _buildVideoWithEffects()
                        : const CircularProgressIndicator(color: Colors.white),
                  ),

                  // Advanced features floating controls overlay
                  if (_showControls)
                    FloatingVideoControls(
                      controller: _videoPlayerController,
                      isPlaying: _isPlaying,
                      showControls: _showControls,
                      onOpenEqualizer: _openEqualizer,
                      onOpenVideoEffects: _openVideoEffects,
                      hasVideoEffects: _brightness != 1.0 ||
                          _contrast != 1.0 ||
                          _saturation != 1.0 ||
                          _hue != 0.0 ||
                          _gamma != 1.0,
                      onOpenAdvancedFeatures: _openAdvancedFeatures,
                      onSeekForward: _seekForward,
                      onSeekBackward: _seekBackward,
                      onToggleStatistics: () =>
                          setState(() => _showStatistics = !_showStatistics),
                      onOpenPlaylist: _openPlaylist,
                      onOpenChapters: _openChapters,
                      onPlaybackSpeedChanged: (speed) {
                        setState(() => _playbackSpeed = speed);
                        _videoPlayerController.setPlaybackSpeed(speed);
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
                      onHardwareAccelerationChanged: (value) =>
                          setState(() => _hardwareAcceleration = value),
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
                      onAudioDelayChanged: (value) =>
                          setState(() => _audioDelay = value),
                      onSubtitleDelayChanged: (value) =>
                          setState(() => _subtitleDelay = value),
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
                      onAudioTrackChanged: (value) =>
                          setState(() => _selectedAudioTrack = value),
                      onSubtitleTrackChanged: (value) =>
                          setState(() => _selectedSubtitleTrack = value),
                      onVideoTrackChanged: (value) =>
                          setState(() => _selectedVideoTrack = value),
                    ),

                  // Statistics overlay
                  if (_showStatistics) _buildStatisticsOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () {
          if (_isFullScreen) {
            _toggleOrientation();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Text(
              widget.video.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          );
        },
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
