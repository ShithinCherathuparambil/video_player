import 'package:flutter/material.dart';

/// App-wide transition system for smooth, liquid animations
class AppTransitions {
  /// Hero animation duration
  static const Duration heroDuration = Duration(milliseconds: 300);

  /// Page transition duration
  static const Duration pageTransitionDuration = Duration(milliseconds: 400);

  /// Micro-interaction duration
  static const Duration microInteractionDuration = Duration(milliseconds: 200);

  /// Create a fade page route
  static PageRoute<T> fadeRoute<T>({
    required Widget page,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Create a slide page route
  static PageRoute<T> slideRoute<T>({
    required Widget page,
    Offset begin = const Offset(1.0, 0.0),
    Offset end = Offset.zero,
    Duration? duration,
    Curve curve = Curves.easeInOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Create a scale page route
  static PageRoute<T> scaleRoute<T>({
    required Widget page,
    double begin = 0.8,
    double end = 1.0,
    Duration? duration,
    Curve curve = Curves.easeOut,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: begin,
          end: end,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Create a liquid page route (combination of scale and fade)
  static PageRoute<T> liquidRoute<T>({
    required Widget page,
    Duration? duration,
    Curve curve = Curves.easeOutCubic,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = Tween<double>(
          begin: 0.9,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: curve,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Create a shared element transition
  static PageRoute<T> sharedElementRoute<T>({
    required Widget page,
    required String heroTag,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? pageTransitionDuration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return Hero(
          tag: heroTag,
          child: child,
        );
      },
    );
  }

  /// Create a custom route with multiple transitions
  static PageRoute<T> customRoute<T>({
    required Widget page,
    required Widget Function(BuildContext, Animation<double>, Animation<double>, Widget) transitionsBuilder,
    Duration? duration,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration ?? pageTransitionDuration,
      transitionsBuilder: transitionsBuilder,
    );
  }

  /// Hero animation for video thumbnails
  static Widget heroVideoThumbnail({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      child: child,
    );
  }

  /// Animated container transition
  static Widget animatedContainer({
    required Widget child,
    required Animation<double> animation,
    Curve curve = Curves.easeInOut,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (animation.value * 0.1),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered list animation
  static Widget staggeredList({
    required List<Widget> children,
    required Animation<double> animation,
    int staggerMilliseconds = 50,
  }) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        
        final delay = index * staggerMilliseconds;
        final delayedAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Interval(
              delay / (children.length * staggerMilliseconds),
              (delay + staggerMilliseconds) / (children.length * staggerMilliseconds),
              curve: Curves.easeOut,
            ),
          ),
        );

        return AnimatedBuilder(
          animation: delayedAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - delayedAnimation.value)),
              child: Opacity(
                opacity: delayedAnimation.value,
                child: child,
              ),
            );
          },
          child: child,
        );
      }).toList(),
    );
  }

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = microInteractionDuration,
    Curve curve = Curves.easeIn,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale in animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = microInteractionDuration,
    Curve curve = Curves.easeOut,
    double begin = 0.8,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in animation
  static Widget slideIn({
    required Widget child,
    Duration duration = microInteractionDuration,
    Curve curve = Curves.easeOut,
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// MX Player-style bounce animation
  static Widget bounceIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 600),
    double overshoot = 0.1,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        final scale = value < 1.0 ? 1.0 + (overshoot * (1.0 - value)) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// MX Player-style liquid transition (smooth scale + fade)
  static Widget liquidTransition({
    required Widget child,
    required Animation<double> animation,
    double beginScale = 0.95,
    double endScale = 1.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: beginScale + ((endScale - beginScale) * animation.value),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// MX Player-style ripple animation
  static Widget ripple({
    required Widget child,
    required Animation<double> animation,
    Color? rippleColor,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (animation.value > 0 && animation.value < 1)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (rippleColor ?? Colors.white)
                        .withOpacity(0.3 * (1 - animation.value)),
                  ),
                  transform: Matrix4.identity()
                    ..scale(animation.value * 2),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }

  /// MX Player-style shimmer effect
  static Widget shimmer({
    required Widget child,
    required Animation<double> animation,
    Color? shimmerColor,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + (animation.value * 2), 0),
              end: Alignment(1.0 + (animation.value * 2), 0),
              colors: [
                Colors.transparent,
                (shimmerColor ?? Colors.white).withOpacity(0.5),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// MX Player-style card entrance animation
  static Widget cardEntrance({
    required Widget child,
    required Animation<double> animation,
    int index = 0,
    int totalItems = 1,
  }) {
    final delay = (index * 100) / (totalItems * 100);
    final adjustedAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Interval(
          delay.clamp(0.0, 1.0),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: adjustedAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - adjustedAnimation.value)),
          child: Opacity(
            opacity: adjustedAnimation.value,
            child: Transform.scale(
              scale: 0.9 + (adjustedAnimation.value * 0.1),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  /// MX Player-style button press animation
  static Widget buttonPress({
    required Widget child,
    required bool isPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: isPressed ? 1.0 : 0.0, end: isPressed ? 0.0 : 1.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 - (value * 0.05),
          child: child,
        );
      },
      child: child,
    );
  }

  /// MX Player-style smooth state change
  static Widget smoothStateChange({
    required Widget child,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      ),
    );
  }
}

