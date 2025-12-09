import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Volume indicator overlay
class VolumeIndicator extends StatelessWidget {
  final double volume;
  final bool isVisible;

  const VolumeIndicator({
    super.key,
    required this.volume,
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
              volume == 0
                  ? LucideIcons.volumeX
                  : volume < 0.5
                      ? LucideIcons.volume1
                      : LucideIcons.volume2,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: volume,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(volume * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
