import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocListener<ThemeBloc, ThemeState>(
        listener: (context, state) {
          if (state is ThemeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: ListView(
          children: [
            const SizedBox(height: 16),
            // Theme Section
            _buildSection(
              context,
              title: 'Appearance',
              children: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: const Text('System Theme'),
                          subtitle: const Text('Follow system theme settings'),
                          value: ThemeMode.system,
                          groupValue: state is ThemeLoaded
                              ? state.themeMode
                              : ThemeMode.system,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              context.read<ThemeBloc>().add(ChangeTheme(value));
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Light Theme'),
                          subtitle: const Text('Always use light theme'),
                          value: ThemeMode.light,
                          groupValue: state is ThemeLoaded
                              ? state.themeMode
                              : ThemeMode.system,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              context.read<ThemeBloc>().add(ChangeTheme(value));
                            }
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Dark Theme'),
                          subtitle: const Text('Always use dark theme'),
                          value: ThemeMode.dark,
                          groupValue: state is ThemeLoaded
                              ? state.themeMode
                              : ThemeMode.system,
                          onChanged: (ThemeMode? value) {
                            if (value != null) {
                              context.read<ThemeBloc>().add(ChangeTheme(value));
                            }
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Grid View'),
                          subtitle: const Text('Display videos in grid layout'),
                          value: state is ThemeLoaded ? state.isGridView : true,
                          onChanged: (bool value) {
                            context
                                .read<ThemeBloc>()
                                .add(ToggleGridView(value));
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Video Section
            _buildSection(
              context,
              title: 'Video',
              children: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Subtitles'),
                          subtitle:
                              const Text('Show subtitles in video player'),
                          value: state is ThemeLoaded
                              ? state.subtitlesEnabled
                              : false,
                          onChanged: (bool value) {
                            context
                                .read<ThemeBloc>()
                                .add(ToggleSubtitles(value));
                          },
                          secondary: Icon(
                            state is ThemeLoaded && state.subtitlesEnabled
                                ? Icons.subtitles
                                : Icons.subtitles_off,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          title: const Text('Video Decoder'),
                          subtitle: Text(
                            state is ThemeLoaded
                                ? _getDecoderDescription(state.videoDecoder)
                                : 'Auto',
                          ),
                          leading: const Icon(Icons.video_settings),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            _showDecoderDialog(context, state);
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Hardware Acceleration'),
                          subtitle: const Text(
                              'Use hardware acceleration for better performance'),
                          value: state is ThemeLoaded
                              ? state.hardwareAcceleration
                              : true,
                          onChanged: (bool value) {
                            context
                                .read<ThemeBloc>()
                                .add(ToggleHardwareAcceleration(value));
                          },
                          secondary: Icon(
                            state is ThemeLoaded && state.hardwareAcceleration
                                ? Icons.speed
                                : Icons.speed_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Security Section
            _buildSection(
              context,
              title: 'Security',
              children: [
                BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    return SwitchListTile(
                      title: const Text('App Lock'),
                      subtitle: const Text(
                          'Require authentication to access the app'),
                      value: state is ThemeLoaded
                          ? state.authenticationEnabled
                          : false,
                      onChanged: (bool value) {
                        context
                            .read<ThemeBloc>()
                            .add(ToggleAuthentication(value));
                      },
                      secondary: Icon(
                        state is ThemeLoaded && state.authenticationEnabled
                            ? Icons.lock
                            : Icons.lock_open,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // About Section
            _buildSection(
              context,
              title: 'About',
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    // TODO: Implement privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy Policy coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  onTap: () {
                    // TODO: Implement terms of service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms of Service coming soon'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  String _getDecoderDescription(String decoder) {
    switch (decoder) {
      case 'auto':
        return 'Auto (Recommended)';
      case 'software':
        return 'Software Decoder';
      case 'hardware':
        return 'Hardware Decoder';
      case 'mediacodec':
        return 'MediaCodec (Android)';
      case 'videotoolbox':
        return 'VideoToolbox (iOS)';
      default:
        return decoder;
    }
  }

  void _showDecoderDialog(BuildContext context, ThemeState state) {
    final decoders = [
      {
        'value': 'auto',
        'title': 'Auto',
        'subtitle': 'Let the system choose the best decoder'
      },
      {
        'value': 'software',
        'title': 'Software',
        'subtitle': 'Use software decoding (compatible but slower)'
      },
      {
        'value': 'hardware',
        'title': 'Hardware',
        'subtitle':
            'Use hardware decoding (faster but may not support all formats)'
      },
      {
        'value': 'mediacodec',
        'title': 'MediaCodec',
        'subtitle': 'Android hardware decoder'
      },
      {
        'value': 'videotoolbox',
        'title': 'VideoToolbox',
        'subtitle': 'iOS hardware decoder'
      },
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Decoder'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: decoders.length,
              itemBuilder: (context, index) {
                final decoder = decoders[index];
                return RadioListTile<String>(
                  title: Text(decoder['title']!),
                  subtitle: Text(decoder['subtitle']!),
                  value: decoder['value']!,
                  groupValue:
                      state is ThemeLoaded ? state.videoDecoder : 'auto',
                  onChanged: (String? value) {
                    if (value != null) {
                      context.read<ThemeBloc>().add(SetVideoDecoder(value));
                      Navigator.of(context).pop();
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
