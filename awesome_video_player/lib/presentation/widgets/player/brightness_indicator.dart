import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Brightness indicator overlay
class BrightnessIndicator extends StatelessWidget {
  final double brightness;
  final bool isVisible;

  const BrightnessIndicator({
    super.key,
    required this.brightness,
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
              brightness < 0.3
                  ? LucideIcons.sunDim
                  : brightness < 0.7
                      ? LucideIcons.sun
                      : LucideIcons.sun,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: brightness,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(brightness * 100).toInt()}%',
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
