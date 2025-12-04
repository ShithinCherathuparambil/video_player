import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/subtitle.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// Subtitle overlay widget with MX Player-style dragging, repositioning, and snap zones
class SubtitleOverlay extends StatefulWidget {
  final Subtitle? currentSubtitle;
  final SubtitleSettings settings;
  final Function(double) onPositionChanged;
  final VoidCallback? onTap;

  const SubtitleOverlay({
    super.key,
    this.currentSubtitle,
    required this.settings,
    required this.onPositionChanged,
    this.onTap,
  });

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay>
    with TickerProviderStateMixin {
  double _currentPosition = 0.1;
  bool _showSnapIndicator = false;
  double? _snapTarget;
  late AnimationController _dragAnimationController;
  late AnimationController _snapAnimationController;
  late Animation<double> _dragScale;
  late Animation<double> _snapPulse;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.settings.position;

    _dragAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _snapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _dragScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _dragAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _snapPulse = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _snapAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _dragAnimationController.dispose();
    _snapAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.position != widget.settings.position) {
      _currentPosition = widget.settings.position;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragAnimationController.forward();
    MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.lightImpact,
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final delta = details.delta.dy / screenHeight;
      final newPosition = (_currentPosition - delta).clamp(0.0, 0.9);
      _currentPosition = newPosition;

      // Check for snap zones
      final zones = [0.1, 0.5, 0.8];
      double closestZone = zones[0];
      double minDistance = (newPosition - zones[0]).abs();

      for (final zone in zones) {
        final distance = (newPosition - zone).abs();
        if (distance < minDistance) {
          minDistance = distance;
          closestZone = zone;
        }
      }

      // Show snap indicator if close to a zone
      if (minDistance < 0.1) {
        _showSnapIndicator = true;
        _snapTarget = closestZone;
        _snapAnimationController.forward();
      } else {
        _showSnapIndicator = false;
        _snapAnimationController.stop();
        _snapAnimationController.reset();
      }

      widget.onPositionChanged(_currentPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _dragAnimationController.reverse();

    // Snap to zone if close enough
    final zones = [0.1, 0.5, 0.8];
    double closestZone = zones[0];
    double minDistance = (_currentPosition - zones[0]).abs();

    for (final zone in zones) {
      final distance = (_currentPosition - zone).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestZone = zone;
      }
    }

    if (minDistance < 0.1) {
      // Animate to snap zone
      _snapToZone(closestZone);
      MicroInteractions.hapticFeedback(
        type: HapticFeedbackType.mediumImpact,
      );
    } else {
      setState(() {
        _showSnapIndicator = false;
        _snapTarget = null;
      });
      _snapAnimationController.stop();
      _snapAnimationController.reset();
    }
  }

  void _snapToZone(double targetZone) {
    // Animate to target zone
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final animation = Tween<double>(
      begin: _currentPosition,
      end: targetZone,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    animation.addListener(() {
      setState(() {
        _currentPosition = animation.value;
        widget.onPositionChanged(_currentPosition);
      });
    });

    controller.forward().then((_) {
      controller.dispose();
      setState(() {
        _showSnapIndicator = false;
        _snapTarget = null;
      });
      _snapAnimationController.stop();
      _snapAnimationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentSubtitle == null) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Snap zone indicators
        if (_showSnapIndicator && _snapTarget != null)
          Positioned(
            bottom: screenHeight * _snapTarget!,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _snapPulse,
              builder: (context, child) {
                return Opacity(
                  opacity: _snapPulse.value * 0.5,
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.4),
                          Colors.white.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                );
              },
            ),
          ),

        // Subtitle overlay
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          bottom: screenHeight * _currentPosition,
          left: 0,
          right: 0,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _dragScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _dragScale.value,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: EdgeInsets.all(widget.settings.padding),
                      decoration: BoxDecoration(
                        // MX Player-style background blur
                        color: Color(widget.settings.backgroundColor)
                            .withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Text(
                            widget.currentSubtitle!.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: widget.settings.fontSize,
                              color: Color(widget.settings.textColor),
                              fontFamily: widget.settings.fontFamily,
                              fontWeight: FontWeight.w500,
                              shadows: [
                                Shadow(
                                  color: Color(widget.settings.outlineColor),
                                  blurRadius: widget.settings.outlineWidth * 2,
                                  offset: Offset(
                                    -widget.settings.outlineWidth / 2,
                                    0,
                                  ),
                                ),
                                Shadow(
                                  color: Color(widget.settings.outlineColor),
                                  blurRadius: widget.settings.outlineWidth * 2,
                                  offset: Offset(
                                    widget.settings.outlineWidth / 2,
                                    0,
                                  ),
                                ),
                                Shadow(
                                  color: Color(widget.settings.outlineColor),
                                  blurRadius: widget.settings.outlineWidth * 2,
                                  offset: Offset(
                                    0,
                                    -widget.settings.outlineWidth / 2,
                                  ),
                                ),
                                Shadow(
                                  color: Color(widget.settings.outlineColor),
                                  blurRadius: widget.settings.outlineWidth * 2,
                                  offset: Offset(
                                    0,
                                    widget.settings.outlineWidth / 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

