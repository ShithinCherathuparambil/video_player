import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart'; // Import States
// import 'package:awesome_video_player/logic/providers/theme_provider.dart'; // Old: To be removed
import 'package:awesome_video_player/presentation/screens/splash_screen.dart';
import 'package:awesome_video_player/presentation/theme/app_themes.dart';

void main() {
  // It's good practice to ensure Flutter bindings are initialized,
  // especially if SharedPreferences (or other platform channel plugins)
  // might be initialized before runApp in some complex setups.
  // WidgetsFlutterBinding.ensureInitialized(); // Already done by ThemeProvider tests, good here too.

  runApp(
    BlocProvider<ThemeBloc>(
      create: (context) => ThemeBloc.create(), // Use the static create method
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        ThemeMode currentThemeMode = ThemeMode.system; // Default
        if (state is ThemeLoaded) {
          currentThemeMode = state.themeMode;
        }
        // Can also handle ThemeInitial, ThemeLoading, ThemeError states here if needed
        // e.g., show a loading screen or default to system if state is ThemeInitial or ThemeError

        return MaterialApp(
          title: 'Awesome Video Player',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: currentThemeMode, // Controlled by ThemeBloc's state
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
