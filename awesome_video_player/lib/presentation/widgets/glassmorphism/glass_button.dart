import 'package:flutter/material.dart';
import 'package:lumeo/core/theme/lumeo_colors.dart';
import 'glass_container.dart';

/// Glassmorphism button widget
/// Modern, translucent button with blur effect
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final double borderWidth;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.blur = 20.0,
    this.opacity = 0.3,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: GlassContainer(
        blur: blur,
        opacity: opacity,
        borderRadius: BorderRadius.circular(borderRadius),
        borderColor: borderColor ?? Colors.white.withOpacity(0.2),
        borderWidth: borderWidth,
        width: width,
        height: height,
        child: Center(child: child),
      ),
    );
  }
}

/// Icon button with glassmorphism effect
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final String? tooltip;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 24.0,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GlassButton(
      onPressed: onPressed,
      width: size * 2,
      height: size * 2,
      borderRadius: size,
      child: Icon(
        icon,
        color: iconColor ?? LumeoColors.textPrimary,
        size: size,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}

