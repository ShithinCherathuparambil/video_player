import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_video_player/logic/providers/theme_provider.dart';
import 'package:awesome_video_player/presentation/screens/splash_screen.dart';
import 'package:awesome_video_player/presentation/theme/app_themes.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Consumer or Provider.of to get the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Awesome Video Player',
      theme: AppThemes.lightTheme, // Your light theme
      darkTheme: AppThemes.darkTheme, // Your dark theme
      themeMode: themeProvider.themeMode, // Controlled by ThemeProvider
      home: const SplashScreen(), // Set SplashScreen as the home
      debugShowCheckedModeBanner: false,
    );
  }
}
