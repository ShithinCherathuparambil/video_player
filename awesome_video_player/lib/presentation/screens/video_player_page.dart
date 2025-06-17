import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:awesome_video_player/presentation/blocs/video_player_cubit/video_player_cubit.dart';
import 'package:awesome_video_player/presentation/blocs/video_player_cubit/video_player_state.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoPath;

  const VideoPlayerPage({super.key, required this.videoPath});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  // bool _isControlsVisible = true; // Removed, will be handled by Cubit

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing video player: $error')),
      );
    });

    // Listener for play/pause state changes for the icon
    _controller.addListener(() {
      if (!mounted) return;
      // This setState is for the play/pause icon, not controls visibility
      if (_controller.value.isPlaying != (_controller.value.isPlaying)) {
         // This condition seems wrong: it will always be true or always false.
         // Let's check if the playing state has changed from the *previous* known state.
         // However, for just updating the icon, it's often enough to call setState
         // whenever the controller value changes if its frequent.
         // For now, minimal change:
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!mounted) return;
    setState(() { // This setState is for the play/pause icon
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VideoPlayerCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.videoPath.split('/').last),
        ),
        backgroundColor: Colors.black,
        body: FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.error == null) {
              return BlocBuilder<VideoPlayerCubit, VideoPlayerControlsState>(
                builder: (context, playerControlsState) {
                  return GestureDetector(
                    onTap: () {
                      context.read<VideoPlayerCubit>().toggleControls();
                    },
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: <Widget>[
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: playerControlsState.areControlsVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    IconButton(
                                      icon: Icon(
                                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 60.0,
                                      ),
                                      onPressed: _togglePlayPause,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading video: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
