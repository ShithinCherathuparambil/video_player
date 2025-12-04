import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/services/video_trim_service.dart';
import 'package:lumeo/core/utils/video_utils.dart';

class VideoTrimPage extends StatefulWidget {
  final VideoFile video;

  const VideoTrimPage({
    super.key,
    required this.video,
  });

  @override
  State<VideoTrimPage> createState() => _VideoTrimPageState();
}

class _VideoTrimPageState extends State<VideoTrimPage> {
  final VideoTrimService _trimService = VideoTrimService();
  Duration _startTime = Duration.zero;
  Duration _endTime = Duration.zero;
  Duration? _videoDuration;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadVideoDuration();
  }

  Future<void> _loadVideoDuration() async {
    final duration = await _trimService.getVideoDuration(widget.video.path);
    setState(() {
      _videoDuration = duration ?? widget.video.duration;
      _endTime = _videoDuration ?? Duration.zero;
    });
  }

  Future<void> _trimVideo() async {
    if (_startTime >= _endTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time must be before end time')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final outputPath = await _trimService.trimVideo(
      inputPath: widget.video.path,
      startTime: _startTime,
      endTime: _endTime,
    );

    setState(() {
      _isProcessing = false;
    });

    if (outputPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video trimmed and saved to: $outputPath')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to trim video')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDuration = _videoDuration ?? Duration.zero;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Trim Video'),
        backgroundColor: Colors.transparent,
      ),
      body: maxDuration == Duration.zero
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start: ${VideoUtils.formatDuration(_startTime)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: _startTime.inSeconds.toDouble(),
                          min: 0,
                          max: maxDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _startTime = Duration(seconds: value.toInt());
                              if (_startTime >= _endTime) {
                                _endTime = Duration(
                                  seconds: (_startTime.inSeconds + 1).clamp(
                                    0,
                                    maxDuration.inSeconds,
                                  ),
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'End: ${VideoUtils.formatDuration(_endTime)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                          value: _endTime.inSeconds.toDouble(),
                          min: 0,
                          max: maxDuration.inSeconds.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _endTime = Duration(seconds: value.toInt());
                              if (_endTime <= _startTime) {
                                _startTime = Duration(
                                  seconds: (_endTime.inSeconds - 1).clamp(0, maxDuration.inSeconds),
                                );
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Duration: ${VideoUtils.formatDuration(_endTime - _startTime)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _trimVideo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator()
                        : const Text('Trim Video'),
                  ),
                ),
              ],
            ),
    );
  }
}

