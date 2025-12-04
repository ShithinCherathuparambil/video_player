import 'package:flutter/material.dart';
import 'package:lumeo/core/theme/app_transitions.dart';
import 'package:lumeo/core/theme/glassmorphism_theme.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// Liquid navigation bar with smooth transitions
class LiquidNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavigationItem> items;

  const LiquidNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidNavigationBar> createState() => _LiquidNavigationBarState();
}

class _LiquidNavigationBarState extends State<LiquidNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTransitions.microInteractionDuration,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(LiquidNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _controller.forward(from: 0.0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassmorphismTheme.glassBottomSheet(
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: widget.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == widget.currentIndex;

            return Expanded(
              child: MicroInteractions.animatedButton(
                onPressed: () {
                  MicroInteractions.hapticFeedback(
                    type: HapticFeedbackType.selectionClick,
                  );
                  widget.onTap(index);
                },
                hapticType: HapticFeedbackType.selectionClick,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: AppTransitions.microInteractionDuration,
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: AppTransitions.scaleIn(
                          begin: isSelected ? 0.9 : 1.0,
                          end: isSelected ? 1.0 : 0.9,
                          child: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: AppTransitions.microInteractionDuration,
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[600],
                        ),
                        child: Text(item.label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Navigation item model
class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating action button with liquid animation
class LiquidFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;

  const LiquidFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
  });

  @override
  State<LiquidFAB> createState() => _LiquidFABState();
}

class _LiquidFABState extends State<LiquidFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
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
    final backgroundColor = widget.backgroundColor ??
        Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor,
                      backgroundColor.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

