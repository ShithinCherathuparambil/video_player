import 'package:flutter/material.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';

/// A widget that provides a gradient background for light theme screens
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool isLightTheme;

  const GradientBackground({
    super.key,
    required this.child,
    this.isLightTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isLightTheme ? AppThemes.lightThemeGradient : null,
        color: isLightTheme ? null : const Color(0xFF121212),
      ),
      child: child,
    );
  }
}

/// A Scaffold with gradient background for light theme
class GradientScaffold extends StatelessWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool extendBody;

  const GradientScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightTheme = brightness == Brightness.light;

    return GradientBackground(
      isLightTheme: isLightTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar != null ? _buildGradientAppBar(context, appBar!) : null,
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        floatingActionButtonLocation: floatingActionButtonLocation,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        extendBody: extendBody,
      ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar(
      BuildContext context, PreferredSizeWidget appBar) {
    final brightness = Theme.of(context).brightness;
    final isLightTheme = brightness == Brightness.light;

    if (!isLightTheme || appBar is! AppBar) {
      return appBar;
    }

    final originalAppBar = appBar;

    return AppBar(
      title: originalAppBar.title,
      leading: originalAppBar.leading,
      actions: originalAppBar.actions,
      centerTitle: originalAppBar.centerTitle,
      elevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: originalAppBar.iconTheme,
      titleTextStyle: originalAppBar.titleTextStyle,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppThemes.lightThemeGradient,
        ),
      ),
    );
  }
}

/// A gradient container for cards and other UI elements
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool useAccentGradient;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.useAccentGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightTheme = brightness == Brightness.light;

    return Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        gradient: isLightTheme
            ? (useAccentGradient
                ? AppThemes.accentGradient
                : AppThemes.lightThemeGradient)
            : null,
        color: isLightTheme ? null : const Color(0xFF1E1E1E),
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLightTheme ? 0.1 : 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A gradient button with the accent colors
class GradientButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const GradientButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLightTheme = brightness == Brightness.light;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Container(
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isLightTheme ? AppThemes.accentGradient : null,
            color: isLightTheme ? null : const Color(0xFF2196F3),
            borderRadius: borderRadius ?? BorderRadius.circular(8),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
