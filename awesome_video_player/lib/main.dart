import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart'; // Added
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart'; // Added
import 'package:awesome_video_player/presentation/theme/app_themes.dart';
import 'package:awesome_video_player/presentation/screens/splash_screen.dart';

void main() {
  runApp(
    BlocProvider<ThemeBloc>(
      // Changed from ChangeNotifierProvider
      create: (_) => ThemeBloc.create(), // Changed to ThemeBloc.create()
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Removed: final themeProvider = Provider.of<ThemeProvider>(context);

    return BlocBuilder<ThemeBloc, ThemeState>(
      // Added BlocBuilder
      builder: (context, themeState) {
        return MaterialApp(
          title: 'Awesome Video Player',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          // Changed to use themeState from ThemeBloc
          themeMode: (themeState is ThemeLoaded)
              ? themeState.themeMode
              : ThemeMode.system,
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
