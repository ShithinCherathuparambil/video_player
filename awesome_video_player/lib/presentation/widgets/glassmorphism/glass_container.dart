import 'dart:ui';
import 'package:flutter/material.dart';

/// Enhanced glassmorphism container with depth, layering, blur variations, and shadow effects
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;
  final int depth; // 0 = surface, 1 = elevated, 2 = floating
  final bool enableShadow;
  final Color? shadowColor;
  final double shadowBlur;
  final double shadowSpread;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.borderColor,
    this.borderWidth = 1.0,
    this.depth = 0,
    this.enableShadow = true,
    this.shadowColor,
    this.shadowBlur = 20.0,
    this.shadowSpread = 0.0,
  });

  double _getBlurForDepth(int depth) {
    switch (depth) {
      case 0:
        return blur;
      case 1:
        return blur * 1.5;
      case 2:
        return blur * 2.0;
      default:
        return blur;
    }
  }

  double _getOpacityForDepth(int depth) {
    switch (depth) {
      case 0:
        return opacity;
      case 1:
        return opacity * 1.2;
      case 2:
        return opacity * 1.4;
      default:
        return opacity;
    }
  }

  List<BoxShadow> _getShadowsForDepth(int depth) {
    if (!enableShadow) return [];

    final baseShadow = BoxShadow(
      color: shadowColor ?? Colors.black.withOpacity(0.15 + (depth * 0.1)),
      blurRadius: shadowBlur + (depth * 10),
      spreadRadius: shadowSpread + (depth * 2),
      offset: Offset(0, 4 + (depth * 4)),
    );

    // Add multiple shadow layers for depth
    return [
      baseShadow,
      if (depth > 0)
        BoxShadow(
          color: shadowColor ?? Colors.black.withOpacity(0.1),
          blurRadius: shadowBlur * 0.5,
          spreadRadius: shadowSpread,
          offset: const Offset(0, 2),
        ),
      if (depth > 1)
        BoxShadow(
          color: shadowColor ?? Colors.black.withOpacity(0.05),
          blurRadius: shadowBlur * 0.3,
          spreadRadius: shadowSpread,
          offset: const Offset(0, 1),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBlur = _getBlurForDepth(depth);
    final effectiveOpacity = _getOpacityForDepth(depth).clamp(0.0, 1.0);
    final shadows = _getShadowsForDepth(depth);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ??
              Colors.white.withOpacity(0.2 + (depth * 0.1)),
          width: borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background blur layer
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(effectiveOpacity),
                      Colors.white.withOpacity(effectiveOpacity * 0.8),
                    ],
                  ),
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                ),
              ),
            ),
            // Content layer
            Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: borderRadius ?? BorderRadius.circular(16),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

