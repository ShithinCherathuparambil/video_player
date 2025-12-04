# 🎬 Lumeo: Complete Implementation Guide
## Next-Generation Video Player - VLC + MX Player Hybrid

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Package Recommendations](#package-recommendations)
3. [Project Structure](#project-structure)
4. [UI/UX Design System](#uiux-design-system)
5. [Core Features Implementation](#core-features-implementation)
6. [Code Examples](#code-examples)
7. [Implementation Roadmap](#implementation-roadmap)
8. [Best Practices](#best-practices)

---

## 🏗️ Architecture Overview

### Tech Stack
- **Framework**: Flutter 3.32.8+ (latest stable)
- **State Management**: BLoC Pattern (already implemented)
- **Video Engine**: `better_player` (primary) + `flutter_vlc_player` (fallback)
- **Local Storage**: `shared_preferences` + `hive`
- **File Management**: `path_provider` + `file_picker`
- **Subtitle Engine**: Custom parser + `flutter_subtitle`
- **Network**: `dio` for streaming
- **Animations**: `flutter_animate` + custom Hero animations
- **Haptics**: `flutter/services.dart` (built-in)

### Architecture Pattern
```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, BLoCs)             │
├─────────────────────────────────────────┤
│         Domain Layer                    │
│  (Entities, Use Cases, Repositories)    │
├─────────────────────────────────────────┤
│         Data Layer                      │
│  (Data Sources, Repositories)          │
├─────────────────────────────────────────┤
│         Core Services                   │
│  (Video Player, Subtitle, Gesture)     │
└─────────────────────────────────────────┘
```

---

## 📦 Package Recommendations

### Required Packages

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Video Playback
  better_player: ^0.0.83
  flutter_vlc_player: ^7.0.0
  wakelock_plus: ^1.2.1
  video_player: ^2.8.2  # Fallback option

  # Subtitle Support
  subtitle_wrapper_package: ^2.0.0
  # Custom subtitle parser (implement locally)

  # File Management
  file_picker: ^8.0.0
  path_provider: ^2.1.1
  permission_handler: ^11.0.0
  photo_manager: ^3.7.1  # Already in use

  # State Management (already in use)
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Network Streaming
  dio: ^5.4.0
  http: ^1.2.0

  # UI Enhancements
  flutter_animate: ^4.5.0
  shimmer: ^3.0.0

  # Utilities
  intl: ^0.19.0
  uuid: ^4.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.7
  mockito: ^5.5.0
  build_runner: ^2.6.0
```

---

## 📁 Complete Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── video_formats.dart
│   │   ├── gesture_config.dart
│   │   └── subtitle_config.dart
│   ├── theme/
│   │   ├── app_themes.dart (exists)
│   │   ├── glassmorphism_theme.dart
│   │   ├── neon_accent_theme.dart
│   │   └── lumeo_colors.dart
│   ├── utils/
│   │   ├── video_utils.dart
│   │   ├── subtitle_utils.dart
│   │   ├── gesture_utils.dart
│   │   ├── file_utils.dart
│   │   └── format_utils.dart
│   ├── services/
│   │   ├── video_player_service.dart (stub exists)
│   │   ├── subtitle_service.dart
│   │   ├── playback_position_service.dart
│   │   ├── decoder_service.dart
│   │   ├── audio_track_service.dart
│   │   └── brightness_service.dart
│   └── extensions/
│       └── duration_extensions.dart
│
├── data/
│   ├── datasources/
│   │   ├── video_local_data_source.dart (exists)
│   │   ├── subtitle_local_data_source.dart
│   │   ├── playback_position_data_source.dart
│   │   └── network_stream_data_source.dart
│   ├── repositories/
│   │   ├── video_repository_impl.dart (exists)
│   │   ├── subtitle_repository_impl.dart
│   │   ├── playback_repository_impl.dart
│   │   └── stream_repository_impl.dart
│   └── models/
│       ├── video_file.dart (exists)
│       ├── subtitle_model.dart
│       ├── playback_position_model.dart
│       └── stream_model.dart
│
├── domain/
│   ├── entities/
│   │   ├── video_file.dart (exists)
│   │   ├── subtitle.dart
│   │   ├── playback_settings.dart
│   │   └── audio_track.dart
│   ├── repositories/
│   │   ├── video_repository.dart (exists)
│   │   ├── subtitle_repository.dart
│   │   ├── playback_repository.dart
│   │   └── stream_repository.dart
│   └── usecases/
│       ├── video_usecases.dart (exists)
│       ├── subtitle_usecases.dart
│       ├── playback_usecases.dart
│       └── stream_usecases.dart
│
└── presentation/
    ├── blocs/
    │   ├── video_player_bloc/ (NEW)
    │   │   ├── video_player_bloc.dart
    │   │   ├── video_player_event.dart
    │   │   └── video_player_state.dart
    │   ├── subtitle_bloc/ (NEW)
    │   │   ├── subtitle_bloc.dart
    │   │   ├── subtitle_event.dart
    │   │   └── subtitle_state.dart
    │   ├── gesture_bloc/ (NEW)
    │   │   ├── gesture_bloc.dart
    │   │   ├── gesture_event.dart
    │   │   └── gesture_state.dart
    │   ├── playlist_bloc/ (NEW)
    │   │   ├── playlist_bloc.dart
    │   │   ├── playlist_event.dart
    │   │   └── playlist_state.dart
    │   └── settings_bloc/ (NEW)
    │       ├── settings_bloc.dart
    │       ├── settings_event.dart
    │       └── settings_state.dart
    │
    ├── screens/
    │   ├── video_player_page.dart (ENHANCE existing)
    │   ├── playlist_viewer_page.dart (NEW)
    │   ├── file_browser_page.dart (NEW)
    │   ├── subtitle_customization_page.dart (NEW)
    │   ├── audio_track_selector_page.dart (NEW)
    │   └── settings_page.dart (ENHANCE existing)
    │
    └── widgets/
        ├── player/
        │   ├── liquid_player_controls.dart (NEW)
        │   ├── gesture_overlay.dart (exists - stub)
        │   ├── subtitle_overlay.dart (NEW)
        │   ├── playback_speed_control.dart (NEW)
        │   ├── audio_track_selector.dart (NEW)
        │   ├── aspect_ratio_selector.dart (NEW)
        │   └── volume_brightness_indicator.dart (NEW)
        ├── glassmorphism/
        │   ├── glass_container.dart (exists)
        │   ├── glass_button.dart (NEW)
        │   └── glass_card.dart (NEW)
        ├── animations/
        │   ├── hero_transitions.dart (NEW)
        │   ├── liquid_transitions.dart (NEW)
        │   └── fade_scale_transition.dart (NEW)
        └── common/
            ├── video_thumbnail.dart (NEW)
            └── loading_indicator.dart (NEW)
```

---

## 🎨 UI/UX Design System

### Color Palette

```dart
// lib/core/theme/lumeo_colors.dart
import 'package:flutter/material.dart';

class LumeoColors {
  // Primary Colors
  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);

  // Accent Colors (Neon)
  static const neonBlue = Color(0xFF00D4FF);
  static const neonPurple = Color(0xFFB026FF);
  static const neonGreen = Color(0xFF00FF88);
  static const neonPink = Color(0xFFFF006E);

  // Background Colors
  static const backgroundDark = Color(0xFF000000); // True black (AMOLED)
  static const backgroundCard = Color(0xFF1A1A1A);
  static const backgroundElevated = Color(0xFF2A2A2A);
  static const glassBackground = Color(0x40FFFFFF);

  // Text Colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textTertiary = Color(0xFF6B7280);

  // Status Colors
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Glassmorphism Colors
  static const glassWhite = Color(0x30FFFFFF);
  static const glassBlack = Color(0x40000000);
}
```

### Typography

```dart
// lib/core/theme/lumeo_typography.dart
import 'package:flutter/material.dart';

class LumeoTypography {
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.25,
  );

  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}
```

---

## 🎮 Core Features Implementation

### 1. Enhanced Video Player Service

See: `lib/core/services/video_player_service.dart` (stub exists)

**Key Features:**
- Hardware/Software decoder switching
- BetterPlayer primary, VLC fallback
- Multi-audio track support
- Playback speed control (0.25x - 4x)
- Volume control
- Position tracking

### 2. Subtitle System

**Subtitle Model:**
```dart
// lib/domain/entities/subtitle.dart
class Subtitle {
  final Duration startTime;
  final Duration endTime;
  final String text;
  final Map<String, dynamic>? styles;

  Subtitle({
    required this.startTime,
    required this.endTime,
    required this.text,
    this.styles,
  });
}

class SubtitleSettings {
  final double fontSize;
  final Color textColor;
  final Color backgroundColor;
  final Color outlineColor;
  final double outlineWidth;
  final String fontFamily;
  final double position; // 0.0 to 1.0 (bottom position)
  final double padding;
  final int delayMs; // Sync delay

  SubtitleSettings({
    this.fontSize = 16.0,
    this.textColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.outlineColor = Colors.black,
    this.outlineWidth = 2.0,
    this.fontFamily = 'Roboto',
    this.position = 0.1,
    this.padding = 8.0,
    this.delayMs = 0,
  });
}
```

### 3. Gesture Control System

**Implementation:**
- Right side vertical swipe → Volume
- Left side vertical swipe → Brightness
- Horizontal swipe → Seek
- Double-tap left → Rewind 10s
- Double-tap right → Forward 10s

See: `lib/presentation/widgets/player/gesture_overlay.dart` (exists)

### 4. Playback Position Service

```dart
// lib/core/services/playback_position_service.dart
class PlaybackPositionService {
  static const String _positionKeyPrefix = 'playback_position_';

  Future<void> savePosition(String videoPath, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_positionKeyPrefix${videoPath.hashCode}',
      position.inMilliseconds,
    );
  }

  Future<Duration?> getPosition(String videoPath) async {
    final prefs = await SharedPreferences.getInstance();
    final milliseconds = prefs.getInt(
      '$_positionKeyPrefix${videoPath.hashCode}',
    );
    return milliseconds != null ? Duration(milliseconds: milliseconds) : null;
  }

  Future<void> clearPosition(String videoPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_positionKeyPrefix${videoPath.hashCode}');
  }
}
```

---

## 💻 Code Examples

### 1. Liquid Player Controls

```dart
// lib/presentation/widgets/player/liquid_player_controls.dart
import 'package:flutter/material.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LiquidPlayerControls extends StatefulWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;
  final VoidCallback? onFullscreen;
  final VoidCallback? onSettings;

  const LiquidPlayerControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onSeek,
    this.onFullscreen,
    this.onSettings,
  });

  @override
  State<LiquidPlayerControls> createState() => _LiquidPlayerControlsState();
}

class _LiquidPlayerControlsState extends State<LiquidPlayerControls>
    with SingleTickerProviderStateMixin {
  bool _isVisible = true;
  late AnimationController _visibilityController;

  @override
  void initState() {
    super.initState();
    _visibilityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _visibilityController.forward();
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    super.dispose();
  }

  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _visibilityController,
      child: GlassContainer(
        blur: 20.0,
        opacity: 0.3,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Center(
                child: _buildPlayPauseButton(),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Row(
            children: [
              if (widget.onFullscreen != null)
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: widget.onFullscreen,
                ),
              if (widget.onSettings != null)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: widget.onSettings,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: widget.onPlayPause,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Icon(
          widget.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      )
          .animate()
          .scale(duration: 200.ms, curve: Curves.easeOut)
          .fadeIn(duration: 200.ms),
    );
  }

  Widget _buildBottomControls() {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * widget.duration.inMilliseconds).toInt(),
                );
                widget.onSeek(newPosition);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(widget.position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    onPressed: () => widget.onSeek(
                      widget.position - const Duration(seconds: 10),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    onPressed: () => widget.onSeek(
                      widget.position + const Duration(seconds: 10),
                    ),
                  ),
                ],
              ),
              Text(
                _formatDuration(widget.duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
```

### 2. Subtitle Overlay with Dragging

```dart
// lib/presentation/widgets/player/subtitle_overlay.dart
import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/subtitle.dart';

class SubtitleOverlay extends StatefulWidget {
  final Subtitle? currentSubtitle;
  final SubtitleSettings settings;
  final Function(double) onPositionChanged;

  const SubtitleOverlay({
    super.key,
    this.currentSubtitle,
    required this.settings,
    required this.onPositionChanged,
  });

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay> {
  double _currentPosition = 0.1;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.settings.position;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final delta = details.delta.dy / screenHeight;
      _currentPosition = (_currentPosition - delta).clamp(0.0, 0.9);
      widget.onPositionChanged(_currentPosition);
    });
  }

  void _snapToZone(double position) {
    // Snap to predefined zones: bottom (0.1), middle (0.5), top (0.8)
    final zones = [0.1, 0.5, 0.8];
    double closestZone = zones[0];
    double minDistance = (position - zones[0]).abs();

    for (final zone in zones) {
      final distance = (position - zone).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestZone = zone;
      }
    }

    setState(() {
      _currentPosition = closestZone;
      widget.onPositionChanged(_currentPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentSubtitle == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: MediaQuery.of(context).size.height * _currentPosition,
      left: 0,
      right: 0,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _snapToZone(_currentPosition),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.all(widget.settings.padding),
            decoration: BoxDecoration(
              color: widget.settings.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.currentSubtitle!.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: widget.settings.fontSize,
                color: widget.settings.textColor,
                fontFamily: widget.settings.fontFamily,
                shadows: [
                  Shadow(
                    color: widget.settings.outlineColor,
                    blurRadius: widget.settings.outlineWidth,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 3. Enhanced Video Player Page

```dart
// Key enhancements to lib/presentation/screens/video_player_page.dart

// Add these imports:
import 'package:lumeo/presentation/widgets/player/liquid_player_controls.dart';
import 'package:lumeo/presentation/widgets/player/gesture_overlay.dart';
import 'package:lumeo/presentation/widgets/player/subtitle_overlay.dart';
import 'package:lumeo/core/services/video_player_service.dart';

// In the build method, wrap video player with:
Stack(
  children: [
    // Video player widget
    BetterPlayerWidget(controller: _playerController),
    
    // Gesture overlay
    GestureOverlay(
      playerService: _videoPlayerService,
      onVolumeChange: () => setState(() {}),
      onBrightnessChange: () => setState(() {}),
      onSeek: () => setState(() {}),
    ),
    
    // Subtitle overlay
    SubtitleOverlay(
      currentSubtitle: _currentSubtitle,
      settings: _subtitleSettings,
      onPositionChanged: (position) {
        setState(() {
          _subtitleSettings = _subtitleSettings.copyWith(position: position);
        });
      },
    ),
    
    // Liquid controls
    if (_showControls)
      LiquidPlayerControls(
        isPlaying: _isPlaying,
        position: _position,
        duration: _duration,
        onPlayPause: _togglePlayPause,
        onSeek: _seekTo,
        onFullscreen: _toggleFullscreen,
        onSettings: _showSettings,
      ),
  ],
)
```

### 4. Playlist Viewer

```dart
// lib/presentation/screens/playlist_viewer_page.dart
import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';

class PlaylistViewerPage extends StatelessWidget {
  final List<VideoFile> videos;
  final int currentIndex;

  const PlaylistViewerPage({
    super.key,
    required this.videos,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Playlist'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView.builder(
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          final isCurrent = index == currentIndex;

          return GlassContainer(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: video.thumbnailBytes != null
                          ? DecorationImage(
                              image: MemoryImage(video.thumbnailBytes!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                ],
              ),
              title: Text(
                video.name,
                style: TextStyle(
                  color: isCurrent ? Colors.blue : Colors.white,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: video.duration != null
                  ? Text(
                      _formatDuration(video.duration!),
                      style: const TextStyle(color: Colors.grey),
                    )
                  : null,
              trailing: isCurrent
                  ? const Icon(Icons.check_circle, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context, index);
              },
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m ${seconds}s';
  }
}
```

### 5. Subtitle Customization Page

```dart
// lib/presentation/screens/subtitle_customization_page.dart
import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/subtitle.dart';

class SubtitleCustomizationPage extends StatefulWidget {
  final SubtitleSettings initialSettings;
  final Function(SubtitleSettings) onSettingsChanged;

  const SubtitleCustomizationPage({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SubtitleCustomizationPage> createState() =>
      _SubtitleCustomizationPageState();
}

class _SubtitleCustomizationPageState
    extends State<SubtitleCustomizationPage> {
  late SubtitleSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Subtitle Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Size'),
          Slider(
            value: _settings.fontSize,
            min: 10,
            max: 32,
            divisions: 22,
            label: _settings.fontSize.toStringAsFixed(0),
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(fontSize: value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Position'),
          Slider(
            value: _settings.position,
            min: 0.0,
            max: 0.9,
            divisions: 9,
            label: '${(_settings.position * 100).toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(position: value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Text Color'),
          _buildColorPicker(
            'Text Color',
            _settings.textColor,
            (color) {
              setState(() {
                _settings = _settings.copyWith(textColor: color);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Outline'),
          Row(
            children: [
              Expanded(
                child: Text('Outline Width: ${_settings.outlineWidth}'),
              ),
              Slider(
                value: _settings.outlineWidth,
                min: 0,
                max: 5,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(outlineWidth: value);
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
            ],
          ),
          _buildColorPicker(
            'Outline Color',
            _settings.outlineColor,
            (color) {
              setState(() {
                _settings = _settings.copyWith(outlineColor: color);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Sync'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _settings = _settings.copyWith(
                      delayMs: _settings.delayMs - 100,
                    );
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
              Text('Delay: ${_settings.delayMs}ms'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _settings = _settings.copyWith(
                      delayMs: _settings.delayMs + 100,
                    );
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    final colors = [
      Colors.white,
      Colors.yellow,
      Colors.cyan,
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.purple,
    ];

    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: currentColor == color ? Colors.white : Colors.grey,
                width: currentColor == color ? 3 : 1,
              ),
            ),
            child: currentColor == color
                ? const Icon(Icons.check, color: Colors.black)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
```

---

## 🗺️ Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
**Priority: Critical**

1. ✅ **Fix Current Issues** (COMPLETED)
   - Favorite icon update
   - Code quality improvements

2. **Add Required Packages**
   ```bash
   flutter pub add better_player flutter_vlc_player wakelock_plus
   flutter pub add dio http
   flutter pub add flutter_animate shimmer
   flutter pub add hive hive_flutter
   ```

3. **Implement Video Player Service**
   - Replace stub with actual implementation
   - Add hardware/software decoder switching
   - Implement playback controls

4. **Create Glassmorphism Theme**
   - Implement glass container widgets
   - Create theme extensions
   - Add color palette

### Phase 2: Core Player Features (Week 3-4)
**Priority: High**

5. **Gesture Controls**
   - Volume swipe (right side)
   - Brightness swipe (left side)
   - Seek swipe (horizontal)
   - Double-tap skip

6. **Subtitle System**
   - Subtitle file loader (.srt, .ass, .vtt)
   - Subtitle parser
   - Subtitle overlay with dragging
   - Subtitle customization UI

7. **Playback Features**
   - Playback speed control (0.25x - 4x)
   - Multi-audio track selection
   - Aspect ratio controls
   - Playback position saving

### Phase 3: Advanced Features (Week 5-6)
**Priority: Medium**

8. **Liquid UI Controls**
   - Animated play/pause button
   - Glassmorphism controls
   - Smooth transitions
   - Haptic feedback

9. **Playlist System**
   - Playlist viewer
   - Auto-play next
   - Recently watched section
   - Continue watching

10. **File Browser Enhancements**
    - Smart folders (Movies/Series/Downloads)
    - Thumbnail previews
    - Quick actions (delete/skip)

### Phase 4: Polish & Advanced (Week 7-8)
**Priority: Low**

11. **Picture-in-Picture**
    - PiP mode implementation
    - Background audio

12. **Network Streaming**
    - HLS/DASH support
    - Network subtitle loading
    - Stream quality selection

13. **Advanced Features**
    - Lock screen mode
    - Orientation lock
    - Audio boost
    - Speed presets

---

## 📐 UI Wireframes

### Home Screen
```
┌─────────────────────────────────────┐
│  [≡]  Lumeo    [🔍] [⚙️] [👤]      │
├─────────────────────────────────────┤
│                                     │
│  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐ │
│  │ 📹  │ │ 📹  │ │ 📹  │ │ 📹  │ │
│  │Title│ │Title│ │Title│ │Title│ │
│  └─────┘ └─────┘ └─────┘ └─────┘ │
│                                     │
│  Continue Watching                  │
│  ┌─────────────────────────────┐   │
│  │  [▶] Video Title            │   │
│  │  45:30 / 1:23:45            │   │
│  │  [━━━━━━━━━━━━━━━━━━━━━━]   │   │
│  └─────────────────────────────┘   │
│                                     │
│  Playlists                          │
│  ┌─────┐ ┌─────┐ ┌─────┐          │
│  │ 📁  │ │ 📁  │ │ 📁  │          │
│  │Name │ │Name │ │Name │          │
│  └─────┘ └─────┘ └─────┘          │
└─────────────────────────────────────┘
```

### Player Screen (Portrait)
```
┌─────────────────────────────────────┐
│  [←]  Video Title    [⋮] [🔒]      │
├─────────────────────────────────────┤
│                                     │
│                                     │
│         [▶] Play Button             │
│                                     │
│                                     │
│  [Subtitle Text Here]               │
│                                     │
├─────────────────────────────────────┤
│  [━━━━━━━━━━━━━━━━━━━━━━━━━━━━]   │
│  00:45 / 1:23:45                   │
│  [⏮] [⏯] [⏭] [🔊] [⚙️] [📱]     │
└─────────────────────────────────────┘
```

### Player Screen (Landscape)
```
┌─────────────────────────────────────────────────────┐
│  [←] Title                    [⋮] [🔒] [📱]        │
├─────────────────────────────────────────────────────┤
│                                                     │
│                                                     │
│              Video Player Area                      │
│                                                     │
│                                                     │
│  [Subtitle Text Here - Draggable]                  │
│                                                     │
├─────────────────────────────────────────────────────┤
│  [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]   │
│  [⏮] [⏯] [⏭] [🔊] [⚙️] [📱] [🔒] [1.0x]        │
└─────────────────────────────────────────────────────┘
```

---

## 🎯 Best Practices

### 1. Performance Optimization
- Use `const` constructors wherever possible
- Implement lazy loading for video lists
- Cache thumbnails and metadata
- Debounce gesture events
- Use `RepaintBoundary` for complex widgets

### 2. State Management
- Keep BLoC events focused and specific
- Emit new state instances (not mutations)
- Use `Equatable` for state comparison
- Handle errors gracefully

### 3. User Experience
- Always show loading states
- Provide haptic feedback
- Smooth animations (60fps target)
- Clear error messages
- Offline-first approach

### 4. Code Quality
- Follow existing BLoC pattern
- Use dependency injection
- Write unit tests
- Document complex logic
- Keep widgets small and focused

---

## 🚀 Quick Start Guide

### Step 1: Add Packages
```bash
flutter pub add better_player flutter_vlc_player wakelock_plus
flutter pub add dio http flutter_animate shimmer
flutter pub add hive hive_flutter
flutter pub get
```

### Step 2: Update Video Player Service
Replace the stub in `lib/core/services/video_player_service.dart` with actual implementation using the packages.

### Step 3: Implement Gesture Controls
The `gesture_overlay.dart` is ready - just integrate it into the video player page.

### Step 4: Add Subtitle System
Create subtitle parser and overlay components.

### Step 5: Enhance UI
Add glassmorphism theme and liquid animations.

---

## 📚 Additional Resources

- Better Player: https://pub.dev/packages/better_player
- Flutter VLC Player: https://pub.dev/packages/flutter_vlc_player
- Glassmorphism Guide: https://glassmorphism.com/
- Flutter Animations: https://docs.flutter.dev/development/ui/animations

---

## ✅ Implementation Checklist

### Foundation
- [ ] Add all required packages
- [ ] Implement VideoPlayerService
- [ ] Create glassmorphism theme
- [ ] Set up project structure

### Core Features
- [ ] Gesture controls (volume, brightness, seek)
- [ ] Subtitle system (load, display, customize)
- [ ] Playback speed control
- [ ] Multi-audio track support
- [ ] Playback position tracking

### Advanced Features
- [ ] Picture-in-Picture mode
- [ ] Background audio
- [ ] Network streaming
- [ ] Auto-play next episode
- [ ] Lock screen mode

### Polish
- [ ] Liquid animations
- [ ] Haptic feedback
- [ ] Playlist viewer
- [ ] File browser enhancements
- [ ] Settings page improvements

---

**Ready to build the future of video playback! 🎬🚀**

