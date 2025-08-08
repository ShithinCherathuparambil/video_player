import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lumeo/core/security/authentication_service.dart';
import 'package:lumeo/domain/usecases/authenticate_user.dart';
import 'package:lumeo/core/security/app_authentication_manager.dart';

/// Authentication overlay screen that appears when app returns from background
class AuthOverlayScreen extends StatefulWidget {
  final VoidCallback onAuthenticationSuccess;
  final VoidCallback? onAuthenticationFailed;

  const AuthOverlayScreen({
    super.key,
    required this.onAuthenticationSuccess,
    this.onAuthenticationFailed,
  });

  @override
  State<AuthOverlayScreen> createState() => _AuthOverlayScreenState();
}

class _AuthOverlayScreenState extends State<AuthOverlayScreen> {
  bool _isAuthenticating = false;
  String _statusMessage = 'Please authenticate to continue';

  late final AuthenticateUser _authenticateUser;

  @override
  void initState() {
    super.initState();

    // Initialize authentication service
    _authenticateUser = AuthenticateUser(AuthenticationService());

    // Start authentication with a delay to ensure proper lifecycle state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _performAuthentication();
        }
      });
    });
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
        // Mark session as authenticated to prevent future auth requests
        AppAuthenticationManager().markSessionAuthenticated();
        debugPrint(
            'AuthOverlayScreen: Authentication successful, marking session as authenticated');
        await Future.delayed(const Duration(milliseconds: 500));
        widget.onAuthenticationSuccess();
      } else {
        _handleAuthenticationFailure(result);
      }
    } catch (e) {
      debugPrint('AuthOverlayScreen: Authentication error: $e');
      _updateStatus('Authentication error');
      await Future.delayed(const Duration(seconds: 1));
      _showRetryDialog();
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

    // Show retry option after delay
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
              if (widget.onAuthenticationFailed != null) {
                widget.onAuthenticationFailed!();
              } else {
                // Default behavior: allow access but show warning
                widget.onAuthenticationSuccess();
              }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.security,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Awesome Video Player',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            if (_isAuthenticating)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            else
              const SizedBox(height: 4),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
