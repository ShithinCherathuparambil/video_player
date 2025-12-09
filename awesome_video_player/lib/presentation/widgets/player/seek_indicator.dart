import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lumeo/core/utils/video_utils.dart';

/// Seek indicator overlay
class SeekIndicator extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final bool isRewind;
  final bool isVisible;

  const SeekIndicator({
    super.key,
    required this.position,
    required this.duration,
    this.isRewind = false,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRewind ? LucideIcons.rotateCcw : LucideIcons.rotateCw,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              VideoUtils.formatDuration(position),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (duration > Duration.zero) ...[
              const SizedBox(height: 4),
              Text(
                '/ ${VideoUtils.formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
