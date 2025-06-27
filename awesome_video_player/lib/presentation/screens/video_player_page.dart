import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/presentation/theme/app_themes.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_state.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:awesome_video_player/domain/usecases/save_video_metadata.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';
import 'package:awesome_video_player/data/repositories/video_repository_impl.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';
import 'package:get_it/get_it.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_event.dart';

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

  // Aspect ratio and subtitle controls
  bool _subtitlesEnabled = true;
  double _aspectRatio = 16 / 9;
  final List<double> _aspectRatios = [16 / 9, 4 / 3, 1 / 1, 21 / 9, 2.35 / 1];
  int _currentAspectRatioIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.video;
    _initializeDependencies();
    _initializeAnimations();
    _initializePlayer();

    // Load subtitle preference from theme bloc
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

    // Wait for initialization
    await _videoPlayerController.initialize();

    // Set aspect ratio to the video's original aspect ratio
    setState(() {
      _aspectRatio = _videoPlayerController.value.aspectRatio;
    });

    // Load last position if resuming
    if (widget.resumeFromLastPosition) {
      _loadLastPosition();
    }

    _createChewieController();
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  void _loadLastPosition() {
    // Load from video's own metadata
    if (widget.video.lastPlayedPosition != null) {
      _lastPosition = widget.video.lastPlayedPosition!;
    } else {
      // Fallback to default position
      _lastPosition = const Duration(seconds: 30);
    }
  }

  void _saveLastPosition() async {
    try {
      final currentPosition = _videoPlayerController.value.position;
      final totalDuration = _videoPlayerController.value.duration;

      // Update video status based on progress and previous status
      VideoStatus newStatus = _currentVideo.status;
      if (totalDuration > Duration.zero) {
        final progress =
            currentPosition.inMilliseconds / totalDuration.inMilliseconds;

        if (progress >= 0.9) {
          // Video is fully watched - mark as last watched
          newStatus = VideoStatus.lastWatched;
        } else if (progress > 0.1) {
          // Video has been watched for more than 10% - mark as watching
          newStatus = VideoStatus.watching;
        } else if (progress > 0) {
          // Video has been started but not much progress - keep current status or mark as new
          if (_currentVideo.status == VideoStatus.new_) {
            newStatus = VideoStatus.watching;
          }
        }
      }

      // Update video with new metadata
      final updatedVideo = _currentVideo.copyWith(
        lastPlayedPosition: currentPosition,
        lastPlayedAt: DateTime.now(),
        status: newStatus,
      );

      // Update the video list instantly
      print('=== Dispatching UpdateVideoStatus ===');
      print('Video path: ${_currentVideo.path}');
      print('New status: $newStatus');
      print('Current position: $currentPosition');

      context.read<VideoListBloc>().add(UpdateVideoStatus(
            videoPath: _currentVideo.path,
            newStatus: newStatus,
            lastPosition: currentPosition,
          ));

      print('UpdateVideoStatus event dispatched');

      // Save to video metadata in background
      await _saveVideoMetadata(updatedVideo);
      _currentVideo = updatedVideo;
    } catch (e) {
      print('Error saving video metadata: $e');
    }
  }

  void _createChewieController() {
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false, // Start in pause state
      looping: false,
      aspectRatio: _aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      showOptions: true,
      subtitle: _subtitlesEnabled ? Subtitles([]) : null,
      placeholder: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
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
              colors: [
                Colors.red[900]!,
                Colors.red[700]!,
              ],
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
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 48,
                  ),
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Listen to player state changes
    _videoPlayerController.addListener(_onPlayerStateChanged);

    // Seek to last position if resuming - do this after controller is created
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
        // Hide controls after 3 seconds when playing
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

    // Save position periodically while playing
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

  void _toggleSubtitles() {
    setState(() {
      _subtitlesEnabled = !_subtitlesEnabled;
    });

    // Update the Chewie controller with new subtitle setting
    if (_chewieController != null) {
      _chewieController!.dispose();
      _createChewieController();
    }

    // Save the preference using BLoC
    context.read<ThemeBloc>().add(ToggleSubtitles(_subtitlesEnabled));
  }

  void _changeAspectRatio() {
    setState(() {
      _currentAspectRatioIndex =
          (_currentAspectRatioIndex + 1) % _aspectRatios.length;
      _aspectRatio = _aspectRatios[_currentAspectRatioIndex];

      // Update Chewie controller
      if (_chewieController != null) {
        _chewieController!.dispose();
        _createChewieController();
      }
    });
  }

  String _getAspectRatioLabel() {
    switch (_currentAspectRatioIndex) {
      case 0:
        return '16:9';
      case 1:
        return '4:3';
      case 2:
        return '1:1';
      case 3:
        return '21:9';
      case 4:
        return '2.35:1';
      default:
        return '16:9';
    }
  }

  Future<bool> _onWillPop() async {
    // If in full screen mode, exit full screen first
    if (_isFullScreen) {
      _toggleOrientation();
      return false; // Don't pop, just exit full screen
    }
    // If not in full screen, allow normal pop
    return true;
  }

  @override
  void dispose() {
    // Save final position and status
    _saveLastPosition();

    _videoPlayerController.removeListener(_onPlayerStateChanged);
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();

    // No need to trigger refresh since we use instant updates

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LastPlayedBloc.create(),
      child: BlocListener<LastPlayedBloc, LastPlayedState>(
        listener: (context, state) {
          // Update last played video when player starts
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
            appBar: _isFullScreen
                ? null
                : AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
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
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                    actions: [
                      // Aspect ratio button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _getAspectRatioLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onPressed: _changeAspectRatio,
                      ),
                      // Subtitle button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _subtitlesEnabled
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8)
                                : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _subtitlesEnabled
                                ? Icons.subtitles
                                : Icons.subtitles_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: _toggleSubtitles,
                      ),
                      // Full screen button
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: _toggleOrientation,
                      ),
                    ],
                  ),
            body: GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                children: [
                  // Video player
                  Center(
                    child: _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : const CircularProgressIndicator(
                            color: Colors.white,
                          ),
                  ),
                  // Custom controls overlay
                  if (_showControls)
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
}
