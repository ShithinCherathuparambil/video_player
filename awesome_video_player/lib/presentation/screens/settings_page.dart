import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          bool isDarkMode = false;
          if (state is ThemeLoaded) {
            isDarkMode = state.themeMode == ThemeMode.dark;
          } else if (state is ThemeInitial || state is ThemeLoading) {
            // Default to false or consider system brightness if preferred for initial states
            // For instance:
            // if (state is ThemeInitial) { // Only on very first load before ThemeBloc emits ThemeLoaded from storage
            //    isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;
            // }
          }
          // If state is ThemeError, it will use the last valid `isDarkMode` or default to false.

          return ListView(
            children: <Widget>[
              ListTile(
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: (bool value) {
                    final newMode = value ? ThemeMode.dark : ThemeMode.light;
                    context.read<ThemeBloc>().add(ChangeTheme(newMode));
                  },
                ),
              ),
              // Placeholder for future "System" theme option
              // if (state is ThemeLoaded)
              //   ListTile(
              //     title: const Text('Follow System Theme'),
              //     trailing: Switch(
              //       value: state.themeMode == ThemeMode.system,
              //       onChanged: (bool value) {
              //         if (value) {
              //           context.read<ThemeBloc>().add(ChangeTheme(ThemeMode.system));
              //         } else {
              //           // When turning off "Follow System", revert to light/dark based on current actual brightness or last explicit choice
              //           // This logic might need refinement depending on desired UX.
              //           var currentActualBrightnessIsDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
              //           context.read<ThemeBloc>().add(ChangeTheme(currentActualBrightnessIsDark ? ThemeMode.dark : ThemeMode.light));
              //         }
              //       },
              //     ),
              //   ),
            ],
          );
        },
      ),
    );
  }
}
