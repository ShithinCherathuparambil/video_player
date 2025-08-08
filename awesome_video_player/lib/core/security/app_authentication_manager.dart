import 'package:flutter/material.dart';
import 'package:lumeo/domain/usecases/check_authentication_required.dart';
import 'package:lumeo/data/repositories/settings_repository_impl.dart';
import 'package:lumeo/data/datasources/settings_local_data_source.dart';
import 'package:lumeo/presentation/screens/auth_overlay_screen.dart';
import 'package:lumeo/main.dart' show navigatorKey;

/// Manages app-wide authentication based on app lifecycle
class AppAuthenticationManager with WidgetsBindingObserver {
  static final AppAuthenticationManager _instance =
      AppAuthenticationManager._internal();
  factory AppAuthenticationManager() => _instance;
  AppAuthenticationManager._internal();

  late final CheckAuthenticationRequired _checkAuthRequired;
  bool _isInitialized = false;
  bool _isAuthOverlayVisible = false;
  bool _wasInBackground = false;
  bool _hasAuthenticatedThisSession = false;
  bool _hasAuthenticatedOnSplash = false;
  bool _isInitialAppStartup = true;

  /// Initialize the authentication manager
  void initialize() {
    if (_isInitialized) return;

    _checkAuthRequired = CheckAuthenticationRequired(
      SettingsRepositoryImpl(localDataSource: SettingsLocalDataSourceImpl()),
    );

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
  }

  /// Dispose the authentication manager
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background
        _wasInBackground = true;
        debugPrint('AppAuthenticationManager: App going to background');
        break;

      case AppLifecycleState.resumed:
        // App is coming back to foreground
        debugPrint(
            'AppAuthenticationManager: App resumed, _wasInBackground=$_wasInBackground, _isAuthOverlayVisible=$_isAuthOverlayVisible, _isInitialAppStartup=$_isInitialAppStartup, _hasAuthenticatedOnSplash=$_hasAuthenticatedOnSplash');

        // Skip authentication during initial app startup to avoid double authentication
        if (_isInitialAppStartup) {
          debugPrint(
              'AppAuthenticationManager: Skipping authentication during initial startup');
          _isInitialAppStartup = false;
          return;
        }

        // Skip authentication if we just authenticated during splash screen
        if (_hasAuthenticatedOnSplash) {
          debugPrint(
              'AppAuthenticationManager: Skipping authentication - already authenticated during splash');
          _wasInBackground = false;
          return;
        }

        if (_wasInBackground && !_isAuthOverlayVisible) {
          // Add a small delay to ensure the app is fully resumed
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_wasInBackground && !_isAuthOverlayVisible) {
              debugPrint(
                  'AppAuthenticationManager: Checking authentication after delay');
              _checkAndShowAuthentication();
            }
          });
        }
        break;

      case AppLifecycleState.detached:
        // App is being terminated - reset all authentication state
        _wasInBackground = false;
        _hasAuthenticatedThisSession = false;
        _hasAuthenticatedOnSplash = false;
        _isInitialAppStartup = true;
        _isAuthOverlayVisible = false;
        debugPrint(
            'AppAuthenticationManager: App terminated, resetting authentication state');
        break;

      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        _wasInBackground = true;
        break;
    }
  }

  /// Check if authentication is required and show overlay if needed
  Future<void> _checkAndShowAuthentication() async {
    try {
      debugPrint(
          'AppAuthenticationManager: Checking if authentication is required...');
      final bool authRequired = await _checkAuthRequired();
      debugPrint(
          'AppAuthenticationManager: Authentication required = $authRequired');

      // Show authentication if required and not already visible
      // Background authentication should always trigger if auth is enabled
      if (authRequired &&
          !_isAuthOverlayVisible &&
          !_hasAuthenticatedThisSession) {
        debugPrint(
            'AppAuthenticationManager: Showing authentication for background return');
        _showAuthOverlay();
      } else {
        debugPrint(
            'AppAuthenticationManager: Not showing authentication - authRequired=$authRequired, _isAuthOverlayVisible=$_isAuthOverlayVisible, _hasAuthenticatedThisSession=$_hasAuthenticatedThisSession');
      }
    } catch (e) {
      // Handle error silently - don't block app usage
      debugPrint('Error checking authentication requirement: $e');
    }
  }

  /// Show the authentication overlay
  void _showAuthOverlay() {
    if (_isAuthOverlayVisible) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    _isAuthOverlayVisible = true;

    // Use a route instead of overlay for better lifecycle management
    navigator.push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuthOverlayScreen(
          onAuthenticationSuccess: () {
            _removeAuthOverlay();
            _wasInBackground = false;
            debugPrint(
                'AppAuthenticationManager: Background authentication successful');
          },
          onAuthenticationFailed: () {
            _removeAuthOverlay();
            _wasInBackground = false;
            debugPrint(
                'AppAuthenticationManager: Background authentication failed');
          },
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        opaque: true,
        barrierDismissible: false,
        fullscreenDialog: true,
      ),
    );
  }

  /// Remove the authentication overlay
  void _removeAuthOverlay() {
    if (_isAuthOverlayVisible) {
      final navigator = navigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.pop();
      }
    }
    _isAuthOverlayVisible = false;
  }

  /// Force show authentication (useful for testing or manual triggers)
  void forceShowAuthentication() {
    if (!_isAuthOverlayVisible) {
      _showAuthOverlay();
    }
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
