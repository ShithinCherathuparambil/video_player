import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// MX Player-inspired button with ripple effects, press animations, and icon animations
class MXStyleButton extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isOutlined;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const MXStyleButton({
    super.key,
    this.child,
    this.onPressed,
    this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.isOutlined = false,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
  }) : assert(
          child != null || (icon != null || label != null),
          'Either child or icon/label must be provided',
        );

  @override
  State<MXStyleButton> createState() => _MXStyleButtonState();
}

class _MXStyleButtonState extends State<MXStyleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;

    setState(() => _isPressed = true);
    await MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.lightImpact,
    );
    _controller.forward().then((_) {
      _controller.reverse();
      setState(() => _isPressed = false);
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ??
        Theme.of(context).colorScheme.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(16);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTapDown: (_) => _handlePress(),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                gradient: widget.isOutlined
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          bgColor,
                          bgColor.withOpacity(0.8),
                        ],
                      ),
                color: widget.isOutlined ? Colors.transparent : null,
                border: widget.isOutlined
                    ? Border.all(
                        color: bgColor,
                        width: 2,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ripple effect
                  if (_isPressed)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: _rippleAnimation.value * 1.5,
                              colors: [
                                fgColor.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Content
                  Center(
                    child: widget.child ??
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon,
                                color: fgColor,
                                size: 20,
                              ),
                              if (widget.label != null) const SizedBox(width: 8),
                            ],
                            if (widget.label != null)
                              Text(
                                widget.label!,
                                style: TextStyle(
                                  color: fgColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

