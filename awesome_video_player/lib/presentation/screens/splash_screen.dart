import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lumeo/core/extensions/extensions.dart';
import 'package:lumeo/presentation/screens/video_list_page.dart';
import 'package:lumeo/presentation/screens/video_player_page.dart';
import 'package:lumeo/core/security/app_authentication_manager.dart';
import 'package:lumeo/core/services/video_intent_service.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';
import 'package:path/path.dart' as path;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;
  String _statusMessage = 'Loading...';

  @override
  void initState() {
    super.initState();

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

      // Check for incoming video file intent
      final videoPath = await VideoIntentService.getInitialVideoPath();
      if (videoPath != null) {
        debugPrint('SplashScreen: Video file received: $videoPath');
        await _handleVideoIntent(videoPath);
        return;
      }

      // Authentication disabled: proceed directly to home
      AppAuthenticationManager().markSplashCompleted();
      _navigateToHome();
    } catch (e) {
      // Handle any errors during initialization
      debugPrint('SplashScreen: Initialization error: $e');
      _updateStatus('Initialization failed');
      await Future.delayed(const Duration(seconds: 1));
      _navigateToHome();
    }
  }

  Future<void> _handleVideoIntent(String videoPath) async {
    try {
      // Resolve content:// URI if needed
      String resolvedPath = videoPath;
      if (videoPath.startsWith('content://')) {
        resolvedPath =
            await VideoIntentService.resolveContentUri(videoPath) ?? videoPath;
      }

      // Extract file name from path
      String fileName = path.basename(resolvedPath);
      if (fileName.isEmpty) {
        fileName = 'Video';
      }

      // Create VideoFile entity
      final videoFile = VideoFile(
        path: resolvedPath,
        name: fileName,
      );

      // Check if file exists (for file:// paths)
      if (resolvedPath.startsWith('file://') ||
          !resolvedPath.startsWith('content://')) {
        final file = File(resolvedPath.replaceFirst('file://', ''));
        if (!await file.exists()) {
          debugPrint('SplashScreen: Video file does not exist: $resolvedPath');
          _navigateToHome();
          return;
        }
      }

      if (!mounted) return;

      // Navigate directly to video player
      AppAuthenticationManager().markSplashCompleted();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(
            video: videoFile,
            resumeFromLastPosition: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('SplashScreen: Error handling video intent: $e');
      _navigateToHome();
    }
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
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Logo with glassmorphism effect
                Image.asset(
                  'splash_logo'.toPng,
                  height: 80.w,
                  width: 80.w,
                  color: AppThemes.primaryColor,
                ),
                const Spacer(),
                Text(
                  'Lumeo',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppThemes.primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
