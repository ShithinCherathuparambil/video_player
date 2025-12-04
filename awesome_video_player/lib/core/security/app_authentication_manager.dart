import 'package:flutter/material.dart';

/// Manages app-wide authentication based on app lifecycle
///
/// NOTE: Authentication has been disabled in this app. This manager is now a
/// no-op shim kept only to avoid touching all call sites. It no longer shows
/// any authentication UI or blocks navigation.
class AppAuthenticationManager with WidgetsBindingObserver {
  static final AppAuthenticationManager _instance =
      AppAuthenticationManager._internal();
  factory AppAuthenticationManager() => _instance;
  AppAuthenticationManager._internal();

  bool _isInitialized = false;
  bool _isAuthOverlayVisible = false;
  bool _wasInBackground = false;
  bool _hasAuthenticatedThisSession = false;
  bool _hasAuthenticatedOnSplash = false;
  bool _isInitialAppStartup = true;

  /// Initialize the authentication manager
  void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;
  }

  /// Dispose the authentication manager
  void dispose() {
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No-op: authentication disabled
    super.didChangeAppLifecycleState(state);
  }

  /// Force show authentication (useful for testing or manual triggers)
  void forceShowAuthentication() {
    // No-op: authentication disabled
  }

  /// Check if authentication overlay is currently visible
  bool get isAuthOverlayVisible => _isAuthOverlayVisible;

  /// Reset the background state (useful after app restart)
  void resetBackgroundState() {
    _wasInBackground = false;
  }

  /// Mark splash authentication as completed (called from splash screen)
  void markSplashAuthenticated() {
    _hasAuthenticatedOnSplash = true;
    _isInitialAppStartup = false; // Splash is done, no longer initial startup
    debugPrint('AppAuthenticationManager: Splash authentication completed');
  }

  /// Mark splash screen as completed (called when splash finishes, with or without auth)
  void markSplashCompleted() {
    _isInitialAppStartup = false; // Splash is done, no longer initial startup
    debugPrint('AppAuthenticationManager: Splash screen completed');
  }

  /// Mark the current session as authenticated (called from background auth)
  void markSessionAuthenticated() {
    _hasAuthenticatedThisSession = true;
    debugPrint('AppAuthenticationManager: Session authentication completed');
  }

  /// Check if splash authentication has been completed
  bool hasSplashAuthenticated() {
    return _hasAuthenticatedOnSplash;
  }

  /// Reset session authentication (useful for testing or when authentication is disabled)
  void resetSessionAuthentication() {
    _hasAuthenticatedThisSession = false;
    _hasAuthenticatedOnSplash = false;
  }

  /// Reset splash authentication state (useful when app is restarted or settings change)
  void resetSplashAuthentication() {
    _hasAuthenticatedOnSplash = false;
    _isInitialAppStartup = true;
    debugPrint('AppAuthenticationManager: Reset splash authentication state');
  }

  /// Get current authentication state for debugging
  Map<String, dynamic> getAuthenticationState() {
    return {
      'isInitialized': _isInitialized,
      'isAuthOverlayVisible': _isAuthOverlayVisible,
      'wasInBackground': _wasInBackground,
      'hasAuthenticatedThisSession': _hasAuthenticatedThisSession,
      'hasAuthenticatedOnSplash': _hasAuthenticatedOnSplash,
      'isInitialAppStartup': _isInitialAppStartup,
    };
  }

  /// Print current authentication state for debugging
  void printAuthenticationState() {
    final state = getAuthenticationState();
    debugPrint('AppAuthenticationManager: Current state: $state');
  }
}
