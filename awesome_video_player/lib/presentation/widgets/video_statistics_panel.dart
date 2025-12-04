import 'package:flutter/material.dart';

/// Video statistics panel widget
class VideoStatisticsPanel extends StatelessWidget {
  final double fps;
  final double bitrate;
  final String codec;
  final String resolution;
  final Duration bufferDuration;
  final Duration position;
  final Duration duration;

  const VideoStatisticsPanel({
    super.key,
    required this.fps,
    required this.bitrate,
    required this.codec,
    required this.resolution,
    required this.bufferDuration,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Video Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('FPS', '${fps.toStringAsFixed(1)}'),
          _buildStatRow('Bitrate', '${bitrate.toStringAsFixed(2)} Mbps'),
          _buildStatRow('Codec', codec.isNotEmpty ? codec : 'Unknown'),
          _buildStatRow('Resolution', resolution.isNotEmpty ? resolution : 'Unknown'),
          _buildStatRow('Buffer', _formatDuration(bufferDuration)),
          _buildStatRow('Position', _formatDuration(position)),
          _buildStatRow('Duration', _formatDuration(duration)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}

