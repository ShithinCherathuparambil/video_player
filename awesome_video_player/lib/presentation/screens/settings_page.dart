import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For dispatching events, context.read<ThemeBloc>() is fine.
    // For reacting to state changes for the Switch value, BlocBuilder is more explicit.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          bool isDarkMode = false; // Default to false
          if (state is ThemeLoaded) {
            isDarkMode = state.themeMode == ThemeMode.dark;
          } else if (state is ThemeInitial || state is ThemeLoading) {
            // Optionally, get current system brightness if ThemeBloc not loaded yet,
            // or disable switch until ThemeLoaded. For simplicity, default to false.
            // var brightness = MediaQuery.of(context).platformBrightness;
            // isDarkMode = brightness == Brightness.dark;
          }
          // If state is ThemeError, switch shows last known or default value.

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
              // Example for ThemeMode selection if you want System/Light/Dark options:
              // if (state is ThemeLoaded) { // Ensure state is loaded to show current selection
              //   ListTile(
              //     title: Text('Theme Mode Selection'),
              //     trailing: DropdownButton<ThemeMode>(
              //       value: state.themeMode,
              //       items: const [
              //         DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              //         DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              //         DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              //       ],
              //       onChanged: (ThemeMode? mode) {
              //         if (mode != null) {
              //           context.read<ThemeBloc>().add(ChangeTheme(mode)); // Assuming ChangeTheme takes ThemeMode
              //         }
              //       },
              //     ),
              //   ),
              // }
            ],
          );
        },
      ),
    );
  }
}
