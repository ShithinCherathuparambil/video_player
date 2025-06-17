import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:awesome_video_player/presentation/screens/splash_screen.dart'; // Correct import
import 'package:awesome_video_player/presentation/theme/app_themes.dart';

void main() {
  // Optional: Ensure bindings are initialized if needed for plugins before runApp.
  // WidgetsFlutterBinding.ensureInitialized();

  runApp(
    BlocProvider<ThemeBloc>(
      create: (context) => ThemeBloc.create(),
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
        ThemeMode currentThemeMode = ThemeMode.system;
        if (state is ThemeLoaded) {
          currentThemeMode = state.themeMode;
        }
        // Other states (Initial, Loading, Error) will use ThemeMode.system by default.

        return MaterialApp(
          title: 'Awesome Video Player',
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: currentThemeMode,
          home: const SplashScreen(), // Correctly set
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
