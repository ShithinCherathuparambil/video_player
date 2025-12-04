import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Micro-interactions utility for smooth UI feedback
class MicroInteractions {
  /// Haptic feedback types
  static Future<void> hapticFeedback({
    HapticFeedbackType type = HapticFeedbackType.lightImpact,
  }) async {
    switch (type) {
      case HapticFeedbackType.lightImpact:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        await HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        await HapticFeedback.vibrate();
        break;
    }
  }

  /// Animated button press effect
  static Widget animatedButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 100),
    double scale = 0.95,
    HapticFeedbackType? hapticType,
  }) {
    return _AnimatedButton(
      child: child,
      onPressed: onPressed,
      duration: duration,
      scale: scale,
      hapticType: hapticType,
    );
  }

  /// Animated icon state transition
  static Widget animatedIcon({
    required IconData icon,
    required bool isActive,
    Color? activeColor,
    Color? inactiveColor,
    double size = 24,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Icon(
          icon,
          color: Color.lerp(inactiveColor, activeColor, value),
          size: size + (value * 2),
        );
      },
    );
  }

  /// Smooth color transition
  static Widget colorTransition({
    required Color beginColor,
    required Color endColor,
    required Animation<double> animation,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          color: Color.lerp(beginColor, endColor, animation.value),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation on press
  static Widget scaleOnPress({
    required Widget child,
    required VoidCallback onPressed,
    double scale = 0.9,
    Duration duration = const Duration(milliseconds: 100),
  }) {
    return _ScaleOnPress(
      child: child,
      onPressed: onPressed,
      scale: scale,
      duration: duration,
    );
  }

  /// Ripple effect
  static Widget ripple({
    required Widget child,
    required VoidCallback onTap,
    Color? rippleColor,
    BorderRadius? borderRadius,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        splashColor: rippleColor,
        highlightColor: rippleColor?.withOpacity(0.1),
        child: child,
      ),
    );
  }
}

/// Haptic feedback type enum
enum HapticFeedbackType {
  lightImpact,
  mediumImpact,
  heavyImpact,
  selectionClick,
  vibrate,
}

/// Animated button widget
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  final double scale;
  final HapticFeedbackType? hapticType;

  const _AnimatedButton({
    required this.child,
    required this.onPressed,
    required this.duration,
    required this.scale,
    this.hapticType,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    if (widget.hapticType != null) {
      MicroInteractions.hapticFeedback(type: widget.hapticType!);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Scale on press widget
class _ScaleOnPress extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double scale;
  final Duration duration;

  const _ScaleOnPress({
    required this.child,
    required this.onPressed,
    required this.scale,
    required this.duration,
  });

  @override
  State<_ScaleOnPress> createState() => _ScaleOnPressState();
}

class _ScaleOnPressState extends State<_ScaleOnPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

