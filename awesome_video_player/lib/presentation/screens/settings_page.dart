import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_video_player/logic/providers/theme_provider.dart';

class SettingsPage extends StatelessWidget { // Changed to StatelessWidget
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.isDarkMode, // Value from ThemeProvider
              onChanged: (bool value) {
                // Call toggleTheme on the provider
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          // Example for ThemeMode selection if you want System/Light/Dark options
          // ListTile(
          //   title: Text('Theme Mode'),
          //   trailing: DropdownButton<ThemeMode>(
          //     value: themeProvider.themeMode,
          //     items: [
          //       DropdownMenuItem(child: Text('System'), value: ThemeMode.system),
          //       DropdownMenuItem(child: Text('Light'), value: ThemeMode.light),
          //       DropdownMenuItem(child: Text('Dark'), value: ThemeMode.dark),
          //     ],
          //     onChanged: (ThemeMode? mode) {
          //       if (mode != null) {
          //         themeProvider.setThemeMode(mode);
          //       }
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
