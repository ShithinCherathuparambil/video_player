import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/services/playback_position_service.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Enhanced playback history page with thumbnails, timestamps, and management
class PlaybackHistoryPage extends StatefulWidget {
  final List<VideoFile> allVideos;

  const PlaybackHistoryPage({
    super.key,
    required this.allVideos,
  });

  @override
  State<PlaybackHistoryPage> createState() => _PlaybackHistoryPageState();
}

class _PlaybackHistoryPageState extends State<PlaybackHistoryPage> {
  final PlaybackPositionService _positionService = PlaybackPositionService();
  List<_HistoryEntry> _historyEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recentlyWatched = await _positionService.getRecentlyWatched(limit: 100);
      final allPositions = await _positionService.getAllPositions();
      final entries = <_HistoryEntry>[];

      // Create a map of video paths to VideoFile for quick lookup
      final videoMap = <String, VideoFile>{};
      for (final video in widget.allVideos) {
        videoMap[video.path] = video;
      }

      for (final entry in recentlyWatched) {
        final hash = entry.key;
        // Find video by matching hash
        final video = widget.allVideos.firstWhere(
          (v) => v.path.hashCode.toString() == hash,
          orElse: () => widget.allVideos.firstWhere(
            (v) => v.path == hash,
            orElse: () => widget.allVideos.first,
          ),
        );

        if (videoMap.containsKey(video.path)) {
          final position = allPositions[hash];
          entries.add(_HistoryEntry(
            video: video,
            lastWatched: entry.value,
            position: position,
          ));
        }
      }

      // Sort by most recent first
      entries.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));

      setState(() {
        _historyEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all playback history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _positionService.clearAllPositions();
      MicroInteractions.hapticFeedback(
        type: HapticFeedbackType.mediumImpact,
      );
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('History cleared'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _removeEntry(_HistoryEntry entry) async {
    await _positionService.clearPosition(entry.video.path);
    await _positionService.clearPosition(entry.video.path); // Clear last watched too
    MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.lightImpact,
    );
    _loadHistory();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playback History'),
        actions: [
          if (_historyEntries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear History',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playback history',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Videos you watch will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historyEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _historyEntries[index];
                      return _buildHistoryCard(context, entry);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, _HistoryEntry entry) {
    final video = entry.video;
    final position = entry.position;
    final progress = position != null && video.duration != null
        ? position.inMilliseconds / video.duration!.inMilliseconds
        : 0.0;

    return Dismissible(
      key: Key('history_${video.path}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      onDismissed: (direction) {
        _removeEntry(entry);
        MicroInteractions.hapticFeedback(
          type: HapticFeedbackType.mediumImpact,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          blur: 20.0,
          opacity: 0.3,
          borderRadius: BorderRadius.circular(16),
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerPage(
                    video: video,
                    resumeFromLastPosition: position != null,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: video.thumbnailBytes != null
                              ? Image.memory(
                                  video.thumbnailBytes!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : video.thumbnailPath != null
                                  ? Image.file(
                                      File(video.thumbnailPath!),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      Icons.play_circle_outline,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                        ),
                        if (position != null && video.duration != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(12),
                                ),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Video info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(entry.lastWatched),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                        if (video.duration != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(video.duration!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              if (position != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${_formatDuration(position)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (video.fileSize != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.storage,
                                size: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatFileSize(video.fileSize!),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showEntryMenu(context, entry);
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

  void _showEntryMenu(BuildContext context, _HistoryEntry entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Resume'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      video: entry.video,
                      resumeFromLastPosition: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text('Start from beginning'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      video: entry.video,
                      resumeFromLastPosition: false,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove from history', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeEntry(entry);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntry {
  final VideoFile video;
  final DateTime lastWatched;
  final Duration? position;

  _HistoryEntry({
    required this.video,
    required this.lastWatched,
    this.position,
  });
}

