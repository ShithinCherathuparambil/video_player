import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';

/// Glassmorphism theme configuration
class GlassmorphismTheme {
  /// Default blur value
  static const double defaultBlur = 10.0;

  /// Default opacity
  static const double defaultOpacity = 0.2;

  /// Default border radius
  static const double defaultBorderRadius = 16.0;

  /// Default border width
  static const double defaultBorderWidth = 1.0;

  /// Light theme glass color
  static Color lightGlassColor = Colors.white;

  /// Dark theme glass color
  static Color darkGlassColor = Colors.black;

  /// Create a glass container with default settings
  static Widget glassContainer({
    required Widget child,
    double? blur,
    double? opacity,
    BorderRadius? borderRadius,
    Color? borderColor,
    double? borderWidth,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
  }) {
    return GlassContainer(
      blur: blur ?? defaultBlur,
      opacity: opacity ?? defaultOpacity,
      borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
      borderColor: borderColor,
      borderWidth: borderWidth ?? defaultBorderWidth,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      child: child,
    );
  }

  /// Create a glass button
  static Widget glassButton({
    required VoidCallback onPressed,
    required Widget child,
    double? blur,
    double? opacity,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
  }) {
    return GlassContainer(
      blur: blur ?? defaultBlur,
      opacity: opacity ?? defaultOpacity,
      borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
          child: child,
        ),
      ),
    );
  }

  /// Create a glass card
  static Widget glassCard({
    required Widget child,
    double? blur,
    double? opacity,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: blur ?? defaultBlur,
                spreadRadius: 0,
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur ?? defaultBlur, sigmaY: blur ?? defaultBlur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity ?? defaultOpacity),
              borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: defaultBorderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Create a glass app bar
  static PreferredSizeWidget glassAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    double? blur,
    double? opacity,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur ?? defaultBlur, sigmaY: blur ?? defaultBlur),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity ?? defaultOpacity),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: defaultBorderWidth,
                ),
              ),
            ),
            child: AppBar(
              title: Text(title),
              leading: leading,
              actions: actions,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  /// Create a glass bottom sheet
  static Widget glassBottomSheet({
    required Widget child,
    double? blur,
    double? opacity,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ??
          const BorderRadius.vertical(top: Radius.circular(defaultBorderRadius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur ?? defaultBlur, sigmaY: blur ?? defaultBlur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity ?? defaultOpacity),
            borderRadius: borderRadius ??
                const BorderRadius.vertical(top: Radius.circular(defaultBorderRadius)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: defaultBorderWidth,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  /// Create a glass dialog
  static Widget glassDialog({
    required Widget child,
    double? blur,
    double? opacity,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur ?? defaultBlur, sigmaY: blur ?? defaultBlur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity ?? defaultOpacity),
            borderRadius: borderRadius ?? BorderRadius.circular(defaultBorderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: defaultBorderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

