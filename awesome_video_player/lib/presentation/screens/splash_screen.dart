import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumeo/core/extensions/extensions.dart';
import 'package:lumeo/presentation/screens/video_list_page.dart';
import 'package:lumeo/core/security/authentication_service.dart';
import 'package:lumeo/domain/usecases/authenticate_user.dart';
import 'package:lumeo/domain/usecases/check_authentication_required.dart';
import 'package:lumeo/data/repositories/settings_repository_impl.dart';
import 'package:lumeo/data/datasources/settings_local_data_source.dart';
import 'package:lumeo/core/security/app_authentication_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;
  bool _isAuthenticating = false;
  String _statusMessage = 'Loading...';

  late final AuthenticationService _authService;
  late final AuthenticateUser _authenticateUser;
  late final CheckAuthenticationRequired _checkAuthRequired;

  @override
  void initState() {
    super.initState();

    // Initialize services
    _authService = AuthenticationService();
    _authenticateUser = AuthenticateUser(_authService);
    _checkAuthRequired = CheckAuthenticationRequired(
      SettingsRepositoryImpl(localDataSource: SettingsLocalDataSourceImpl()),
    );

    // Print current authentication state for debugging
    AppAuthenticationManager().printAuthenticationState();

    // Start the initialization process
    _initializeApp();

    // Timer for fade-in animation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Check if authentication is required
      final bool authRequired = await _checkAuthRequired();

      if (authRequired) {
        // Check if we've already authenticated during splash in this app launch
        if (AppAuthenticationManager().hasSplashAuthenticated()) {
          // Already authenticated during splash, skip
          debugPrint(
              'SplashScreen: Already authenticated during splash, skipping');
          _navigateToHome();
          return;
        }

        // Check if biometric authentication is available
        final bool biometricAvailable =
            await _authenticateUser.isBiometricAvailable();

        if (biometricAvailable) {
          await _performAuthentication();
        } else {
          // Authentication is enabled but biometric is not available
          _updateStatus('Authentication not available');
          await Future.delayed(const Duration(seconds: 1));
          AppAuthenticationManager().markSplashCompleted();
          _navigateToHome();
        }
      } else {
        // No authentication required, proceed to home
        debugPrint(
            'SplashScreen: No authentication required, proceeding to home');
        AppAuthenticationManager().markSplashCompleted();
        _navigateToHome();
      }
    } catch (e) {
      // Handle any errors during initialization
      debugPrint('SplashScreen: Initialization error: $e');
      _updateStatus('Initialization failed');
      await Future.delayed(const Duration(seconds: 1));
      AppAuthenticationManager().markSplashCompleted();
      _navigateToHome();
    }
  }

  Future<void> _performAuthentication() async {
    if (!mounted) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Please authenticate to continue';
    });

    try {
      final result = await _authenticateUser(
        reason: 'Authenticate to access Awesome Video Player',
      );

      if (!mounted) return;

      if (result.isSuccess) {
        _updateStatus('Authentication successful');
        // Mark splash authentication as completed
        AppAuthenticationManager().markSplashAuthenticated();
        debugPrint(
            'SplashScreen: Authentication successful, marking splash as authenticated');
        await Future.delayed(const Duration(milliseconds: 500));
        _navigateToHome();
      } else {
        _handleAuthenticationFailure(result);
      }
    } catch (e) {
      debugPrint('SplashScreen: Authentication error: $e');
      _updateStatus('Authentication error');
      await Future.delayed(const Duration(seconds: 1));
      _navigateToHome();
    }
  }

  void _handleAuthenticationFailure(AuthenticationResult result) {
    String message;
    switch (result) {
      case AuthenticationResult.failure:
        message = 'Authentication failed. Please try again.';
        break;
      case AuthenticationResult.unavailable:
        message = 'Authentication not available';
        break;
      case AuthenticationResult.notEnrolled:
        message = 'No biometric enrolled';
        break;
      case AuthenticationResult.lockedOut:
        message = 'Authentication locked. Try again later.';
        break;
      case AuthenticationResult.permanentlyLockedOut:
        message = 'Authentication permanently locked';
        break;
      default:
        message = 'Authentication error occurred';
    }

    _updateStatus(message);

    // Show retry option or navigate after delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _showRetryDialog();
      }
    });
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
            'Authentication is required to access the app. Would you like to try again?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performAuthentication();
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToHome();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const VideoListPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A4C93), // Purple
              Color(0xFF8E44AD), // Purple-Pink
              Color(0xFFE91E63), // Pink
              Color(0xFFFF6B35), // Orange-Red
              Color(0xFFFFB347), // Orange-Yellow
            ],
            stops: [0.0, 0.2, 0.5, 0.9, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(seconds: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Custom play button icon with white color
                // Container(
                //   width: 120,
                //   height: 120,
                //   decoration: BoxDecoration(
                //     color: Colors.white.withValues(alpha: 0.9),
                //     shape: BoxShape.circle,
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withValues(alpha: 0.2),
                //         blurRadius: 20,
                //         offset: const Offset(0, 10),
                //       ),
                //     ],
                //   ),
                //   child: const Icon(
                //     Icons.play_arrow,
                //     size: 60,
                //     color: Color(0xFF6A4C93),
                //   ),
                // ),
                Image.asset(
                  'splash_logo'.toPng,
                  height: 60,
                  width: 60,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Lumeo',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                if (_isAuthenticating)
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF6A4C93)),
                  )
                else
                  const SizedBox(height: 4),
                const SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF6A4C93).withValues(alpha: 0.8),
                    shadows: [
                      const Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
