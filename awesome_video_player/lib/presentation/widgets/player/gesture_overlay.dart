import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/services/video_player_service.dart';
import 'package:lumeo/presentation/widgets/player/volume_indicator.dart';
import 'package:lumeo/presentation/widgets/player/brightness_indicator.dart';
import 'package:lumeo/presentation/widgets/player/seek_indicator.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// Gesture overlay for video player controls with MX Player-style enhancements
/// Features: Visual zones, smooth animations, enhanced haptic feedback
class GestureOverlay extends StatefulWidget {
  final VideoPlayerService playerService;
  final double? initialVolume;
  final ValueChanged<double>? onVolumeChanged;
  final VoidCallback? onVolumeChange;
  final VoidCallback? onBrightnessChange;
  final VoidCallback? onSeek;

  const GestureOverlay({
    super.key,
    required this.playerService,
    this.initialVolume,
    this.onVolumeChanged,
    this.onVolumeChange,
    this.onBrightnessChange,
    this.onSeek,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay>
    with TickerProviderStateMixin {
  double _initialVolume = 0.5;
  double _currentVolume = 0.5;
  double _initialBrightness = 1.0;
  double _currentBrightness = 1.0;
  Duration _initialPosition = Duration.zero;
  Duration _currentPosition = Duration.zero;
  
  bool _isVolumeControl = false;
  bool _isBrightnessControl = false;
  bool _isSeekControl = false;
  bool _showVolumeIndicator = false;
  bool _showBrightnessIndicator = false;
  bool _showSeekIndicator = false;
  bool _isRewind = false;
  bool _showZoneIndicator = false;
  String _zoneLabel = '';
  
  Timer? _indicatorTimer;
  late AnimationController _zoneAnimationController;
  late AnimationController _indicatorFadeController;
  late Animation<double> _zoneOpacity;
  late Animation<double> _indicatorFade;

  @override
  void initState() {
    super.initState();
    // Initialize volume from widget parameter or default
    _currentVolume = widget.initialVolume ?? 0.5;
    _initialVolume = _currentVolume;
    
    _zoneAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _indicatorFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _zoneOpacity = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _zoneAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _indicatorFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _indicatorFadeController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void didUpdateWidget(GestureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVolume != null && widget.initialVolume != oldWidget.initialVolume) {
      _currentVolume = widget.initialVolume!;
      _initialVolume = _currentVolume;
    }
  }

  @override
  void dispose() {
    _indicatorTimer?.cancel();
    _zoneAnimationController.dispose();
    _indicatorFadeController.dispose();
    super.dispose();
  }

  void _hideIndicator() {
    setState(() {
      _showVolumeIndicator = false;
      _showBrightnessIndicator = false;
      _showSeekIndicator = false;
      _showZoneIndicator = false;
    });
    _indicatorTimer?.cancel();
    _indicatorFadeController.reverse();
    _zoneAnimationController.reverse();
  }

  void _showIndicatorForDuration(Duration duration) {
    _indicatorTimer?.cancel();
    _indicatorFadeController.forward();
    _indicatorTimer = Timer(duration, _hideIndicator);
  }

  void _showZone(String label, bool isRightSide) {
    setState(() {
      _showZoneIndicator = true;
      _zoneLabel = label;
    });
    _zoneAnimationController.forward();
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _zoneAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          // Vertical swipe for volume/brightness
          onVerticalDragStart: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isRightSide = details.globalPosition.dx > screenWidth / 2;
            
            if (isRightSide) {
              // Volume control (right side)
              _isVolumeControl = true;
              _initialVolume = _currentVolume;
              MicroInteractions.hapticFeedback(
                type: HapticFeedbackType.mediumImpact,
              );
              _showZone('Volume', true);
            } else {
              // Brightness control (left side)
              _isBrightnessControl = true;
              _initialBrightness = _currentBrightness;
              MicroInteractions.hapticFeedback(
                type: HapticFeedbackType.mediumImpact,
              );
              _showZone('Brightness', false);
            }
          },
          onVerticalDragUpdate: (details) {
            final screenHeight = MediaQuery.of(context).size.height;
            final delta = -details.delta.dy / screenHeight; // Invert for natural feel

            if (_isVolumeControl) {
              final newVolume = (_initialVolume + delta).clamp(0.0, 1.0);
              setState(() {
                _currentVolume = newVolume;
                _showVolumeIndicator = true;
              });
              widget.playerService.setVolume(newVolume);
              widget.onVolumeChanged?.call(newVolume);
              widget.onVolumeChange?.call();
              _showIndicatorForDuration(const Duration(seconds: 2));
            } else if (_isBrightnessControl) {
              final newBrightness = (_initialBrightness + delta).clamp(0.0, 1.0);
              setState(() {
                _currentBrightness = newBrightness;
                _showBrightnessIndicator = true;
              });
              _setBrightness(newBrightness);
              widget.onBrightnessChange?.call();
              _showIndicatorForDuration(const Duration(seconds: 2));
            }
          },
          onVerticalDragEnd: (_) {
            _isVolumeControl = false;
            _isBrightnessControl = false;
            _showIndicatorForDuration(const Duration(seconds: 1));
          },

          // Horizontal swipe for seeking
          onHorizontalDragStart: (details) {
            _isSeekControl = true;
            _initialPosition = widget.playerService.position;
            MicroInteractions.hapticFeedback(
              type: HapticFeedbackType.heavyImpact,
            );
            _showZone('Seek', true);
          },
          onHorizontalDragUpdate: (details) {
            if (!_isSeekControl) return;

            final screenWidth = MediaQuery.of(context).size.width;
            final deltaSeconds = (details.delta.dx / screenWidth) *
                widget.playerService.duration.inSeconds;

            final newPosition = _initialPosition +
                Duration(seconds: deltaSeconds.toInt());
            final clampedPosition = _clampDuration(
              newPosition,
              Duration.zero,
              widget.playerService.duration,
            );

            setState(() {
              _currentPosition = clampedPosition;
              _showSeekIndicator = true;
              _isRewind = details.delta.dx < 0;
            });
            
            widget.playerService.seekTo(clampedPosition);
            widget.onSeek?.call();
            _showIndicatorForDuration(const Duration(seconds: 2));
          },
          onHorizontalDragEnd: (_) {
            _isSeekControl = false;
            _showIndicatorForDuration(const Duration(seconds: 1));
          },

          // Double tap for quick skip
          onDoubleTapDown: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isLeftSide = details.localPosition.dx < screenWidth / 2;

            MicroInteractions.hapticFeedback(
              type: HapticFeedbackType.selectionClick,
            );

            if (isLeftSide) {
              // Rewind 10 seconds
              widget.playerService.seekRelative(Duration(seconds: -10));
              setState(() {
                _currentPosition = widget.playerService.position;
                _showSeekIndicator = true;
                _isRewind = true;
              });
            } else {
              // Forward 10 seconds
              widget.playerService.seekRelative(Duration(seconds: 10));
              setState(() {
                _currentPosition = widget.playerService.position;
                _showSeekIndicator = true;
                _isRewind = false;
              });
            }

            _showIndicatorForDuration(const Duration(milliseconds: 500));
          },

          child: Container(color: Colors.transparent),
        ),
        
        // MX Player-style zone indicators
        AnimatedBuilder(
          animation: _zoneOpacity,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: !_showZoneIndicator,
              child: Opacity(
                opacity: _zoneOpacity.value,
                child: _buildZoneIndicator(),
              ),
            );
          },
        ),

        // Indicators with smooth fade animations
        AnimatedBuilder(
          animation: _indicatorFade,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: !_showVolumeIndicator,
              child: Opacity(
                opacity: _showVolumeIndicator ? _indicatorFade.value : 0.0,
                child: VolumeIndicator(volume: _currentVolume),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _indicatorFade,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: !_showBrightnessIndicator,
              child: Opacity(
                opacity: _showBrightnessIndicator ? _indicatorFade.value : 0.0,
                child: BrightnessIndicator(brightness: _currentBrightness),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _indicatorFade,
          builder: (context, child) {
            return IgnorePointer(
              ignoring: !_showSeekIndicator,
              child: Opacity(
                opacity: _showSeekIndicator ? _indicatorFade.value : 0.0,
                child: SeekIndicator(
                  position: _currentPosition,
                  duration: widget.playerService.duration,
                  isRewind: _isRewind,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _setBrightness(double brightness) async {
    // Note: Setting system brightness requires the screen_brightness package
    // For now, we use a workaround with Flutter's SystemChrome
    // To fully implement, add: screen_brightness: ^0.2.2+1 to pubspec.yaml
    // Then use: await ScreenBrightness().setScreenBrightness(brightness);
    try {
      // Clamp brightness between 0.0 and 1.0
      final clampedBrightness = brightness.clamp(0.0, 1.0);
      debugPrint('Setting brightness to: $clampedBrightness');
      
      // TODO: Uncomment when screen_brightness package is added:
      // final screenBrightness = ScreenBrightness();
      // await screenBrightness.setScreenBrightness(clampedBrightness);
      
      // For now, this is a placeholder that will work when the package is added
    } catch (e) {
      debugPrint('Error setting brightness: $e');
    }
  }

  Widget _buildZoneIndicator() {
    if (!_showZoneIndicator) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            _zoneLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Duration _clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
