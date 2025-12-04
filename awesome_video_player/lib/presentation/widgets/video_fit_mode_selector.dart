import 'package:flutter/material.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';

/// Video fit mode selector widget
/// Allows users to choose how video is displayed (contain, cover, fill, etc.)
class VideoFitModeSelector extends StatelessWidget {
  final BoxFit currentFitMode;
  final ValueChanged<BoxFit> onFitModeChanged;

  const VideoFitModeSelector({
    super.key,
    required this.currentFitMode,
    required this.onFitModeChanged,
  });

  static const Map<BoxFit, String> _fitModeLabels = {
    BoxFit.contain: 'Fit (Original)',
    BoxFit.cover: 'Fill',
    BoxFit.fill: 'Stretch',
    BoxFit.fitWidth: 'Fit Width',
    BoxFit.fitHeight: 'Fit Height',
    BoxFit.none: 'None',
    BoxFit.scaleDown: 'Scale Down',
  };

  static const Map<BoxFit, IconData> _fitModeIcons = {
    BoxFit.contain: Icons.fit_screen,
    BoxFit.cover: Icons.crop_free,
    BoxFit.fill: Icons.aspect_ratio,
    BoxFit.fitWidth: Icons.fit_screen_outlined,
    BoxFit.fitHeight: Icons.fit_screen_outlined,
    BoxFit.none: Icons.crop_original,
    BoxFit.scaleDown: Icons.zoom_out,
  };

  static const Map<BoxFit, String> _fitModeDescriptions = {
    BoxFit.contain: 'Fits video to screen while preserving aspect ratio (recommended)',
    BoxFit.cover: 'Fills screen, may crop video edges',
    BoxFit.fill: 'Stretches video to fill screen (may distort)',
    BoxFit.fitWidth: 'Fits video width to screen width',
    BoxFit.fitHeight: 'Fits video height to screen height',
    BoxFit.none: 'Shows video at original size',
    BoxFit.scaleDown: 'Scales down if larger than screen, otherwise original size',
  };

  @override
  Widget build(BuildContext context) {
    final fitModes = [
      BoxFit.contain,
      BoxFit.cover,
      BoxFit.fill,
      BoxFit.fitWidth,
      BoxFit.fitHeight,
      BoxFit.none,
      BoxFit.scaleDown,
    ];

    return GlassContainer(
      blur: 20.0,
      opacity: 0.3,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Video Fit Mode',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...fitModes.map((fitMode) {
            final isSelected = fitMode == currentFitMode;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  onFitModeChanged(fitMode);
                  MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _fitModeIcons[fitMode],
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fitModeLabels[fitMode] ?? fitMode.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _fitModeDescriptions[fitMode] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

