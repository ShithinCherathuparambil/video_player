import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/widgets/gradient_background.dart';
import 'package:lumeo/presentation/screens/subtitle_customization_page.dart';
import 'package:lumeo/domain/entities/subtitle.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:lumeo/core/services/ui_preferences_service.dart';
import 'package:lumeo/core/services/advanced_features_service.dart';
import 'package:lumeo/core/services/playback_position_service.dart';
import 'package:lumeo/presentation/widgets/playback_speed_selector.dart';
import 'package:lumeo/presentation/screens/privacy_policy_page.dart';
import 'package:lumeo/presentation/screens/terms_of_service_page.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final UIPreferencesService _uiPreferencesService = UIPreferencesService();
  final AdvancedFeaturesService _advancedFeaturesService = AdvancedFeaturesService();
  
  // UI Preferences state
  bool _autoLoadSubtitles = true;
  bool _rememberPosition = true;
  bool _autoPlayNext = true;
  double _defaultPlaybackSpeed = 1.0;
  bool _volumeGesture = true;
  bool _brightnessGesture = true;
  bool _seekGesture = true;
  bool _doubleTapSkip = true;
  bool _hardwareAcceleration = true;
  bool _networkCaching = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    _fadeController.forward();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uiPrefs = await _uiPreferencesService.loadPreferences();
    final advancedPrefs = await _advancedFeaturesService.loadPreferences();
    
    if (mounted) {
      setState(() {
        _autoLoadSubtitles = uiPrefs['autoLoadSubtitles'] ?? true;
        _rememberPosition = advancedPrefs['rememberPosition'] ?? true;
        _autoPlayNext = advancedPrefs['autoPlayNext'] ?? true;
        _defaultPlaybackSpeed = (uiPrefs['defaultPlaybackSpeed'] ?? 1.0).toDouble();
        _volumeGesture = uiPrefs['volumeGesture'] ?? true;
        _brightnessGesture = uiPrefs['brightnessGesture'] ?? true;
        _seekGesture = uiPrefs['seekGesture'] ?? true;
        _doubleTapSkip = uiPrefs['doubleTapSkip'] ?? true;
        _hardwareAcceleration = advancedPrefs['hardwareAcceleration'] ?? true;
        _networkCaching = advancedPrefs['networkCaching'] ?? true;
      });
    }
  }

  Future<void> _saveAllPreferences() async {
    await _uiPreferencesService.savePreferences(
      autoLoadSubtitles: _autoLoadSubtitles,
      rememberPosition: _rememberPosition,
      autoPlayNext: _autoPlayNext,
      defaultPlaybackSpeed: _defaultPlaybackSpeed,
      volumeGesture: _volumeGesture,
      brightnessGesture: _brightnessGesture,
      seekGesture: _seekGesture,
      doubleTapSkip: _doubleTapSkip,
      hardwareAcceleration: _hardwareAcceleration,
      networkCaching: _networkCaching,
    );
    
    // Also update advanced features service for rememberPosition and autoPlayNext
    final advancedPrefs = await _advancedFeaturesService.loadPreferences();
    await _advancedFeaturesService.savePreferences(
      hardwareAcceleration: _hardwareAcceleration,
      deinterlace: advancedPrefs['deinterlace'] ?? false,
      frameDrop: advancedPrefs['frameDrop'] ?? true,
      networkCaching: _networkCaching,
      networkCacheSize: advancedPrefs['networkCacheSize'] ?? 1000,
      audioSync: advancedPrefs['audioSync'] ?? true,
      audioDelay: (advancedPrefs['audioDelay'] ?? 0.0).toDouble(),
      subtitleDelay: (advancedPrefs['subtitleDelay'] ?? 0.0).toDouble(),
      showTimeRemaining: advancedPrefs['showTimeRemaining'] ?? true,
      showBuffering: advancedPrefs['showBuffering'] ?? true,
      showQuality: advancedPrefs['showQuality'] ?? true,
      rememberPosition: _rememberPosition,
      autoPlayNext: _autoPlayNext,
      shuffleEnabled: advancedPrefs['shuffleEnabled'] ?? false,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ListView(
            children: [
              SizedBox(height: 16.h),
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
                        _buildMXStyleSwitchTile(
                          context,
                          title: 'Grid View',
                          subtitle: 'Display videos in grid layout',
                          value: state is ThemeLoaded ? state.isGridView : true,
                          icon: state is ThemeLoaded && state.isGridView
                              ? Icons.grid_view
                              : Icons.view_list,
                          onChanged: (bool value) async {
                            await MicroInteractions.hapticFeedback(
                              type: HapticFeedbackType.lightImpact,
                            );
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
                        _buildMXStyleSwitchTile(
                          context,
                          title: 'Subtitles',
                          subtitle: 'Show subtitles in video player',
                          value: state is ThemeLoaded
                              ? state.subtitlesEnabled
                              : false,
                          icon: state is ThemeLoaded && state.subtitlesEnabled
                              ? Icons.subtitles
                              : Icons.subtitles_off,
                          onChanged: (bool value) async {
                            await MicroInteractions.hapticFeedback(
                              type: HapticFeedbackType.lightImpact,
                            );
                            context
                                .read<ThemeBloc>()
                                .add(ToggleSubtitles(value));
                          },
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
            // Subtitle Settings Section
            _buildSection(
              context,
              title: 'Subtitles',
              children: [
                ListTile(
                  title: const Text('Subtitle Settings'),
                  subtitle: const Text('Customize subtitle appearance and behavior'),
                  leading: const Icon(Icons.subtitles),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    final defaultSettings = const SubtitleSettings();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubtitleCustomizationPage(
                          initialSettings: defaultSettings,
                          onSettingsChanged: (settings) {
                            // Save subtitle settings
                            _saveSubtitleSettings(settings);
                          },
                        ),
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-load Subtitles'),
                  subtitle: const Text('Automatically load subtitle files'),
                  value: _autoLoadSubtitles,
                  onChanged: (value) async {
                    setState(() => _autoLoadSubtitles = value);
                    await _uiPreferencesService.savePreference('autoLoadSubtitles', value);
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Playback Settings Section
            _buildSection(
              context,
              title: 'Playback',
              children: [
                SwitchListTile(
                  title: const Text('Remember Position'),
                  subtitle: const Text('Resume videos where you left off'),
                  value: _rememberPosition,
                  onChanged: (value) async {
                    setState(() => _rememberPosition = value);
                    await _saveAllPreferences();
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                SwitchListTile(
                  title: const Text('Auto-play Next'),
                  subtitle: const Text('Automatically play next video in playlist'),
                  value: _autoPlayNext,
                  onChanged: (value) async {
                    setState(() => _autoPlayNext = value);
                    await _saveAllPreferences();
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                ListTile(
                  title: const Text('Default Playback Speed'),
                  subtitle: Text('${_defaultPlaybackSpeed}x'),
                  leading: const Icon(Icons.speed),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    double? selectedSpeed;
                    await showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PlaybackSpeedSelector(
                        currentSpeed: _defaultPlaybackSpeed,
                        onSpeedChanged: (speed) {
                          selectedSpeed = speed;
                          Navigator.pop(context);
                        },
                      ),
                    );
                    if (selectedSpeed != null && mounted) {
                      setState(() => _defaultPlaybackSpeed = selectedSpeed!);
                      await _uiPreferencesService.savePreference('defaultPlaybackSpeed', selectedSpeed!);
                      MicroInteractions.hapticFeedback(type: HapticFeedbackType.mediumImpact);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Gesture Settings Section
            _buildSection(
              context,
              title: 'Gestures',
              children: [
                SwitchListTile(
                  title: const Text('Volume Gesture'),
                  subtitle: const Text('Swipe right side to adjust volume'),
                  value: _volumeGesture,
                  onChanged: (value) async {
                    setState(() => _volumeGesture = value);
                    await _uiPreferencesService.savePreference('volumeGesture', value);
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                SwitchListTile(
                  title: const Text('Brightness Gesture'),
                  subtitle: const Text('Swipe left side to adjust brightness'),
                  value: _brightnessGesture,
                  onChanged: (value) async {
                    setState(() => _brightnessGesture = value);
                    await _uiPreferencesService.savePreference('brightnessGesture', value);
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                SwitchListTile(
                  title: const Text('Seek Gesture'),
                  subtitle: const Text('Swipe horizontally to seek'),
                  value: _seekGesture,
                  onChanged: (value) async {
                    setState(() => _seekGesture = value);
                    await _uiPreferencesService.savePreference('seekGesture', value);
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                SwitchListTile(
                  title: const Text('Double-tap Skip'),
                  subtitle: const Text('Double-tap to skip 10 seconds'),
                  value: _doubleTapSkip,
                  onChanged: (value) async {
                    setState(() => _doubleTapSkip = value);
                    await _uiPreferencesService.savePreference('doubleTapSkip', value);
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Advanced Settings Section
            _buildSection(
              context,
              title: 'Advanced',
              children: [
                SwitchListTile(
                  title: const Text('Hardware Acceleration'),
                  subtitle: const Text('Use hardware decoder when available'),
                  value: _hardwareAcceleration,
                  onChanged: (value) async {
                    setState(() => _hardwareAcceleration = value);
                    await _saveAllPreferences();
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                SwitchListTile(
                  title: const Text('Network Caching'),
                  subtitle: const Text('Cache network streams for smoother playback'),
                  value: _networkCaching,
                  onChanged: (value) async {
                    setState(() => _networkCaching = value);
                    await _saveAllPreferences();
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  },
                ),
                ListTile(
                  title: const Text('Clear Watch History'),
                  subtitle: const Text('Remove all saved playback positions'),
                  leading: const Icon(Icons.history),
                  onTap: () {
                    _showClearHistoryDialog(context);
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
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServicePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMXStyleSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: value
              ? [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.surface,
                ]
              : [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.95),
                ],
        ),
        border: Border.all(
          color: value
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: value ? 1.5 : 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        value: value,
        onChanged: onChanged,
        secondary: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: value
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      depth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: Colors.white10),
          ...children,
        ],
      ),
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

  Future<void> _saveSubtitleSettings(SubtitleSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('subtitle_fontSize', settings.fontSize);
      await prefs.setInt('subtitle_textColor', settings.textColor);
      await prefs.setInt('subtitle_backgroundColor', settings.backgroundColor);
      await prefs.setInt('subtitle_outlineColor', settings.outlineColor);
      await prefs.setDouble('subtitle_outlineWidth', settings.outlineWidth);
      await prefs.setString('subtitle_fontFamily', settings.fontFamily);
      await prefs.setDouble('subtitle_position', settings.position);
      await prefs.setDouble('subtitle_padding', settings.padding);
      await prefs.setInt('subtitle_delayMs', settings.delayMs);
    } catch (e) {
      debugPrint('Error saving subtitle settings: $e');
    }
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Watch History'),
        content: const Text(
          'This will remove all saved playback positions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final positionService = PlaybackPositionService();
              await positionService.clearAllPositions();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Watch history cleared successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
                MicroInteractions.hapticFeedback(type: HapticFeedbackType.mediumImpact);
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
