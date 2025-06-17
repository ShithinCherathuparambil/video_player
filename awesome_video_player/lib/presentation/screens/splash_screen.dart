import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // For BlocProvider if needed by VideoListPage
import 'package:awesome_video_player/presentation/screens/video_list_page.dart';
// Import ThemeBloc if VideoListPage or its descendants expect it directly from SplashScreen's context,
// though it's typically provided higher in main.dart or in test setups.
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();

    // Timer for navigation
    Timer(const Duration(seconds: 3), () {
      if (mounted) { // Check if the widget is still in the tree
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const VideoListPage()),
        );
      }
    });

    // Timer for fade-in animation
    // Using a microtask to ensure the first frame is built before setState is called.
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        setState(() {
          _visible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AnimatedOpacity(
          opacity: _visible ? 1.0 : 0.0,
          duration: const Duration(seconds: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const FlutterLogo(size: 100),
              const SizedBox(height: 20),
              const Text(
                'Awesome Video Player',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
