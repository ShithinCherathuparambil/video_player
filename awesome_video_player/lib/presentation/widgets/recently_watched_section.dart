import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/services/playback_position_service.dart';
import 'package:lumeo/presentation/widgets/lazy_thumbnail.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/core/utils/video_utils.dart';

/// Recently watched section widget
class RecentlyWatchedSection extends StatefulWidget {
  final List<VideoFile> allVideos;

  const RecentlyWatchedSection({
    super.key,
    required this.allVideos,
  });

  @override
  State<RecentlyWatchedSection> createState() => _RecentlyWatchedSectionState();
}

class _RecentlyWatchedSectionState extends State<RecentlyWatchedSection> {
  final PlaybackPositionService _positionService = PlaybackPositionService();
  List<VideoFile> _recentlyWatchedVideos = [];

  @override
  void initState() {
    super.initState();
    _loadRecentlyWatched();
  }

  Future<void> _loadRecentlyWatched() async {
    final recentlyWatched = await _positionService.getRecentlyWatched(limit: 10);
    final videos = <VideoFile>[];

    for (final entry in recentlyWatched) {
      final videoPath = entry.key;
      try {
        final video = widget.allVideos.firstWhere(
          (v) => v.path.hashCode.toString() == videoPath,
        );
        if (!videos.contains(video)) {
          videos.add(video);
        }
      } catch (e) {
        // Video not found in current list, skip
        continue;
      }
    }

    setState(() {
      _recentlyWatchedVideos = videos;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_recentlyWatchedVideos.isEmpty) {
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
                'Recently Watched',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full history page
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => PlaybackHistoryPage()));
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _recentlyWatchedVideos.length,
            itemBuilder: (context, index) {
              final video = _recentlyWatchedVideos[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LazyThumbnail(
                            videoPath: video.path,
                            thumbnailBytes: video.thumbnailBytes,
                            width: 120,
                            height: 160,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (video.duration != null)
                        Text(
                          VideoUtils.formatDuration(video.duration!),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

