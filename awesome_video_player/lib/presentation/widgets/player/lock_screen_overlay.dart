import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Lock screen overlay for video player
class LockScreenOverlay extends StatefulWidget {
  final bool isLocked;
  final VoidCallback onLockChanged;
  final Widget child;

  const LockScreenOverlay({
    super.key,
    required this.isLocked,
    required this.onLockChanged,
    required this.child,
  });

  @override
  State<LockScreenOverlay> createState() => _LockScreenOverlayState();
}

class _LockScreenOverlayState extends State<LockScreenOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isLocked)
          GestureDetector(
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onLockChanged();
            },
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Screen Locked',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Long press to unlock',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

