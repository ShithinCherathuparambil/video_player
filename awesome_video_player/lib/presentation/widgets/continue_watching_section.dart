import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/services/playback_position_service.dart';
import 'package:lumeo/presentation/widgets/continue_watching_card.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';

/// Continue watching section widget
class ContinueWatchingSection extends StatefulWidget {
  final List<VideoFile> allVideos;

  const ContinueWatchingSection({
    super.key,
    required this.allVideos,
  });

  @override
  State<ContinueWatchingSection> createState() => _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection> {
  final PlaybackPositionService _positionService = PlaybackPositionService();
  List<VideoFile> _continueWatchingVideos = [];
  Map<String, Duration> _positions = {};

  @override
  void initState() {
    super.initState();
    _loadContinueWatching();
  }

  Future<void> _loadContinueWatching() async {
    final positions = await _positionService.getAllPositions();
    final continueVideos = <VideoFile>[];

    for (final video in widget.allVideos) {
      final hash = video.path.hashCode.toString();
      if (positions.containsKey(hash)) {
        final position = positions[hash]!;
        final duration = video.duration;
        
        // Only show if not finished (less than 90% watched)
        if (duration != null && position.inMilliseconds < duration.inMilliseconds * 0.9) {
          continueVideos.add(video);
        }
      }
    }

    // Sort by last watched time (most recent first)
    final lastWatchedMap = <String, DateTime>{};
    for (final video in continueVideos) {
      final lastWatched = await _positionService.getLastWatched(video.path);
      if (lastWatched != null) {
        lastWatchedMap[video.path] = lastWatched;
      }
    }
    
    continueVideos.sort((a, b) {
      final aTime = lastWatchedMap[a.path];
      final bTime = lastWatchedMap[b.path];
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime); // Most recent first
    });

    setState(() {
      _continueWatchingVideos = continueVideos.take(10).toList();
      _positions = positions;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_continueWatchingVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Continue Watching',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Show all continue watching
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _continueWatchingVideos.length,
            itemBuilder: (context, index) {
              final video = _continueWatchingVideos[index];
              final hash = video.path.hashCode.toString();
              final position = _positions[hash];

              return SizedBox(
                width: 300,
                child: ContinueWatchingCard(
                  video: video,
                  position: position,
                  duration: video.duration,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(
                          video: video,
                          resumeFromLastPosition: true,
                        ),
                      ),
                    );
                  },
                  onRemove: () {
                    _positionService.clearPosition(video.path);
                    _loadContinueWatching();
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

