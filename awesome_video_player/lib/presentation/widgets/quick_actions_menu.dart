import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// MX Player-style quick actions menu with floating buttons
class QuickActionsMenu extends StatefulWidget {
  final VoidCallback? onSeekForward;
  final VoidCallback? onSeekBackward;
  final VoidCallback? onSpeedSelector;
  final VoidCallback? onSubtitleToggle;
  final VoidCallback? onAudioToggle;
  final double currentSpeed;
  final bool subtitlesEnabled;
  final bool audioEnabled;

  const QuickActionsMenu({
    super.key,
    this.onSeekForward,
    this.onSeekBackward,
    this.onSpeedSelector,
    this.onSubtitleToggle,
    this.onAudioToggle,
    this.currentSpeed = 1.0,
    this.subtitlesEnabled = true,
    this.audioEnabled = true,
  });

  @override
  State<QuickActionsMenu> createState() => _QuickActionsMenuState();
}

class _QuickActionsMenuState extends State<QuickActionsMenu>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late AnimationController _buttonController;
  late Animation<double> _expandAnimation;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
    MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.mediumImpact,
    );
  }

  Future<void> _handleButtonPress(VoidCallback? callback) async {
    if (callback == null) return;
    await MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.lightImpact,
    );
    _buttonController.forward().then((_) {
      _buttonController.reverse();
    });
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Quick action buttons
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _expandAnimation.value,
                child: Transform.scale(
                  scale: _expandAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.forward_10,
                        label: '+10s',
                        onPressed: widget.onSeekForward,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionButton(
                        icon: Icons.replay_10,
                        label: '-10s',
                        onPressed: widget.onSeekBackward,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionButton(
                        icon: Icons.speed,
                        label: '${widget.currentSpeed}x',
                        onPressed: widget.onSpeedSelector,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionButton(
                        icon: widget.subtitlesEnabled
                            ? Icons.subtitles
                            : Icons.subtitles_off,
                        label: 'Subs',
                        onPressed: widget.onSubtitleToggle,
                        isActive: widget.subtitlesEnabled,
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionButton(
                        icon: widget.audioEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        label: 'Audio',
                        onPressed: widget.onAudioToggle,
                        isActive: widget.audioEnabled,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Main toggle button
          AnimatedBuilder(
            animation: _buttonScale,
            builder: (context, child) {
              return Transform.scale(
                scale: _buttonScale.value,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleMenu,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: _isExpanded ? 0.125 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _isExpanded ? Icons.close : Icons.add,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    if (onPressed == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleButtonPress(onPressed),
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      Theme.of(context).colorScheme.surface.withOpacity(0.8),
                    ]
                  : [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                    ],
            ),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

