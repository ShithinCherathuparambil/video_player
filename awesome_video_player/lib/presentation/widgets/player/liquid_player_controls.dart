import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// Liquid player controls with MX Player-style design
/// Features: Floating buttons, smooth animations, haptic feedback
class LiquidPlayerControls extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final VoidCallback? onFullscreen;
  final VoidCallback? onSettings;
  final VoidCallback? onLock;
  final bool isLocked;
  final VoidCallback? onSeekForward;
  final VoidCallback? onSeekBackward;

  const LiquidPlayerControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
    this.onFullscreen,
    this.onSettings,
    this.onLock,
    this.isLocked = false,
    this.onSeekForward,
    this.onSeekBackward,
  });

  @override
  State<LiquidPlayerControls> createState() => _LiquidPlayerControlsState();
}

class _LiquidPlayerControlsState extends State<LiquidPlayerControls>
    with TickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _visibilityController;
  late AnimationController _playPauseController;
  late AnimationController _buttonScaleController;
  late Animation<double> _playPauseScale;
  late Animation<double> _buttonScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _playPauseScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _playPauseController,
        curve: Curves.easeInOut,
      ),
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _buttonScaleController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _visibilityController,
        curve: Curves.easeInOut,
      ),
    );

    _visibilityController.forward();
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _playPauseController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    });
  }

  Future<void> _handlePlayPause() async {
    await MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.mediumImpact,
    );
    _playPauseController.forward().then((_) {
      _playPauseController.reverse();
    });
    widget.onPlayPause();
  }

  Future<void> _handleButtonPress(VoidCallback? callback) async {
    if (callback == null) return;
    await MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.lightImpact,
    );
    _buttonScaleController.forward().then((_) {
      _buttonScaleController.reverse();
    });
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GlassContainer(
        blur: 25.0,
        opacity: 0.4,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  // Floating skip buttons (MX Player style)
                  Positioned(
                    left: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildFloatingButton(
                        icon: Icons.replay_10,
                        onPressed: widget.onSeekBackward != null
                            ? () => _handleButtonPress(widget.onSeekBackward)
                            : null,
                        label: '-10s',
                      ),
                    ),
                  ),
                  // Center play/pause button
                  Center(
                    child: _buildPlayPauseButton(),
                  ),
                  // Floating skip forward button
                  Positioned(
                    right: 20,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _buildFloatingButton(
                        icon: Icons.forward_10,
                        onPressed: widget.onSeekForward != null
                            ? () => _handleButtonPress(widget.onSeekForward)
                            : null,
                        label: '+10s',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMXStyleButton(
              icon: Icons.arrow_back,
              onPressed: () {
                MicroInteractions.hapticFeedback(
                  type: HapticFeedbackType.lightImpact,
                );
                Navigator.of(context).pop();
              },
            ),
            Row(
              children: [
                if (widget.onLock != null)
                  _buildMXStyleButton(
                    icon: widget.isLocked ? Icons.lock : Icons.lock_open,
                    onPressed: () => _handleButtonPress(widget.onLock),
                  ),
                if (widget.onFullscreen != null)
                  _buildMXStyleButton(
                    icon: Icons.fullscreen,
                    onPressed: () => _handleButtonPress(widget.onFullscreen),
                  ),
                if (widget.onSettings != null)
                  _buildMXStyleButton(
                    icon: Icons.settings,
                    onPressed: () => _handleButtonPress(widget.onSettings),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMXStyleButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return AnimatedBuilder(
      animation: _buttonScale,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScale.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback? onPressed,
    String? label,
  }) {
    if (onPressed == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.black.withOpacity(0.6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    if (label != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayPauseButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_playPauseScale, _fadeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _playPauseScale.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: GestureDetector(
              onTap: _handlePlayPause,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    widget.isPlaying ? Icons.pause : Icons.play_arrow,
                    key: ValueKey(widget.isPlaying),
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // MX Player-style seek bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.25),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.15),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10,
                  pressedElevation: 8,
                ),
                trackHeight: 3.0,
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 20,
                ),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) async {
                  await MicroInteractions.hapticFeedback(
                    type: HapticFeedbackType.selectionClick,
                  );
                  final newPosition = Duration(
                    milliseconds: (value * widget.duration.inMilliseconds).toInt(),
                  );
                  widget.onSeek(newPosition);
                },
              ),
            ),
            const SizedBox(height: 8),
            // Time labels with MX Player style
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(widget.position),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _formatDuration(widget.duration),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
}

