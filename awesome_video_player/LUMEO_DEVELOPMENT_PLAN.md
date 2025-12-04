# 🎬 Lumeo: Next-Generation Video Player
## Complete Development Blueprint

### Vision Statement
**Lumeo = VLC's Power + MX Player's UX + Modern Flutter UI**

A premium, ad-free video player that combines universal format support with a liquid, intuitive user experience.

---

## 📐 Architecture Overview

### Tech Stack
- **Framework**: Flutter 3.32.8+ (latest stable)
- **Video Engine**: `better_player` (primary) + `flutter_vlc_player` (fallback)
- **State Management**: BLoC Pattern (already implemented)
- **Local Storage**: `shared_preferences` + `hive` (for metadata)
- **File Management**: `path_provider` + `file_picker`
- **Subtitle Engine**: `flutter_subtitle` + custom parser
- **Network**: `dio` (for streaming)
- **Animations**: `flutter_animate` + custom Hero animations
- **Haptics**: `flutter_haptic_feedback`

### Package Recommendations

```yaml
dependencies:
  # Video Playback
  better_player: ^0.0.83
  flutter_vlc_player: ^7.0.0  # Fallback for unsupported formats
  wakelock_plus: ^1.2.1
  
  # Subtitle Support
  flutter_subtitle: ^1.0.0
  subtitle_wrapper_package: ^2.0.0
  
  # File Management
  file_picker: ^8.0.0
  path_provider: ^2.1.1
  permission_handler: ^11.0.0
  
  # State Management (already in use)
  flutter_bloc: ^8.1.6
  
  # Storage
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Network Streaming
  dio: ^5.4.0
  http: ^1.2.0
  
  # UI Enhancements
  flutter_animate: ^4.5.0
  glassmorphism: ^3.0.0
  shimmer: ^3.0.0
  
  # Gestures & Haptics
  flutter_haptic_feedback: ^0.6.0
  gesture_detector: ^1.0.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.1.0
  equatable: ^2.0.5
```

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── video_formats.dart
│   │   └── gesture_config.dart
│   ├── theme/
│   │   ├── app_themes.dart (already exists)
│   │   ├── glassmorphism_theme.dart
│   │   └── neon_accent_theme.dart
│   ├── utils/
│   │   ├── video_utils.dart
│   │   ├── subtitle_utils.dart
│   │   └── gesture_utils.dart
│   └── services/
│       ├── video_player_service.dart
│       ├── subtitle_service.dart
│       ├── playback_position_service.dart
│       └── decoder_service.dart
│
├── data/
│   ├── datasources/
│   │   ├── video_local_data_source.dart (exists)
│   │   ├── subtitle_local_data_source.dart
│   │   └── playback_position_data_source.dart
│   ├── repositories/
│   │   ├── video_repository_impl.dart (exists)
│   │   ├── subtitle_repository_impl.dart
│   │   └── playback_repository_impl.dart
│   └── models/
│       ├── video_file.dart (exists)
│       ├── subtitle_model.dart
│       └── playback_position_model.dart
│
├── domain/
│   ├── entities/
│   │   ├── video_file.dart (exists)
│   │   ├── subtitle.dart
│   │   └── playback_settings.dart
│   ├── repositories/
│   │   ├── video_repository.dart (exists)
│   │   ├── subtitle_repository.dart
│   │   └── playback_repository.dart
│   └── usecases/
│       ├── video_usecases.dart (exists)
│       ├── subtitle_usecases.dart
│       └── playback_usecases.dart
│
└── presentation/
    ├── blocs/
    │   ├── video_player_bloc/ (NEW - main player)
    │   ├── subtitle_bloc/ (NEW)
    │   ├── gesture_bloc/ (NEW)
    │   ├── playlist_bloc/ (NEW)
    │   └── settings_bloc/ (NEW)
    ├── screens/
    │   ├── video_player_page.dart (ENHANCE existing)
    │   ├── playlist_viewer_page.dart (NEW)
    │   ├── file_browser_page.dart (NEW)
    │   └── settings_page.dart (ENHANCE existing)
    └── widgets/
        ├── player/
        │   ├── liquid_player_controls.dart (NEW)
        │   ├── gesture_overlay.dart (NEW)
        │   ├── subtitle_overlay.dart (NEW)
        │   └── playback_speed_control.dart (NEW)
        ├── glassmorphism/
        │   ├── glass_container.dart (NEW)
        │   └── glass_button.dart (NEW)
        └── animations/
            ├── hero_transitions.dart (NEW)
            └── liquid_transitions.dart (NEW)
```

---

## 🎨 UI/UX Design System

### Design Principles
1. **Liquid Transitions**: All navigation uses Hero animations
2. **Glassmorphism**: Frosted glass effects on controls
3. **Adaptive Layouts**: Different UIs for portrait/landscape
4. **Haptic Feedback**: Tactile response for all interactions
5. **Dark-First**: AMOLED-optimized dark theme

### Color Palette

```dart
// lib/core/theme/lumeo_colors.dart
class LumeoColors {
  // Primary
  static const primary = Color(0xFF6366F1); // Indigo
  static const primaryDark = Color(0xFF4F46E5);
  
  // Accents
  static const neonBlue = Color(0xFF00D4FF);
  static const neonPurple = Color(0xFFB026FF);
  
  // Backgrounds
  static const backgroundDark = Color(0xFF000000); // True black
  static const backgroundCard = Color(0xFF1A1A1A);
  static const glassBackground = Color(0x40FFFFFF);
  
  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
}
```

---

## 🎮 Core Features Implementation

### 1. Enhanced Video Player Service

```dart
// lib/core/services/video_player_service.dart
class VideoPlayerService {
  BetterPlayerController? _controller;
  FlutterVlcPlayerController? _vlcController;
  DecoderType _currentDecoder = DecoderType.hardware;
  
  Future<void> initializePlayer({
    required String videoPath,
    required VideoFile video,
    DecoderType? preferredDecoder,
  }) async {
    // Try hardware decoder first
    if (preferredDecoder == DecoderType.hardware) {
      try {
        await _initBetterPlayer(videoPath, video);
        _currentDecoder = DecoderType.hardware;
      } catch (e) {
        // Fallback to VLC
        await _initVlcPlayer(videoPath, video);
        _currentDecoder = DecoderType.software;
      }
    }
  }
  
  // Gesture handlers
  void handleVolumeSwipe(double delta) { }
  void handleBrightnessSwipe(double delta) { }
  void handleSeekSwipe(double delta) { }
}
```

### 2. Gesture Control System

```dart
// lib/presentation/widgets/player/gesture_overlay.dart
class GestureOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Volume control (right side)
        if (details.globalPosition.dx > MediaQuery.of(context).size.width / 2) {
          _adjustVolume(details.delta.dy);
        } 
        // Brightness control (left side)
        else {
          _adjustBrightness(details.delta.dy);
        }
      },
      onHorizontalDragUpdate: (details) {
        _seekVideo(details.delta.dx);
      },
      onDoubleTap: (details) {
        // Left half: rewind 10s
        if (details.localPosition.dx < MediaQuery.of(context).size.width / 2) {
          _seekRelative(-10);
        } 
        // Right half: forward 10s
        else {
          _seekRelative(10);
        }
      },
      child: Container(color: Colors.transparent),
    );
  }
}
```

### 3. Subtitle System

```dart
// lib/presentation/widgets/player/subtitle_overlay.dart
class SubtitleOverlay extends StatefulWidget {
  final SubtitleModel subtitle;
  final SubtitleSettings settings;
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: settings.position,
      child: Draggable(
        onDragEnd: (details) {
          // Snap to zones
          _snapToZone(details.offset);
        },
        child: Container(
          padding: EdgeInsets.all(settings.padding),
          decoration: BoxDecoration(
            color: settings.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subtitle.text,
            style: TextStyle(
              fontSize: settings.fontSize,
              color: settings.textColor,
              fontFamily: settings.fontFamily,
              shadows: [
                Shadow(
                  color: settings.outlineColor,
                  blurRadius: settings.outlineWidth,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 4. Liquid Player Controls

```dart
// lib/presentation/widgets/player/liquid_player_controls.dart
class LiquidPlayerControls extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        children: [
          // Top bar with title and settings
          _buildTopBar(),
          
          // Center play/pause button with liquid animation
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom controls with seek bar
          _buildBottomControls(),
        ],
      ),
    );
  }
}
```

---

## 🚀 Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Set up enhanced video player service
- [ ] Implement decoder fallback system
- [ ] Create glassmorphism theme
- [ ] Build basic gesture overlay

### Phase 2: Core Features (Week 3-4)
- [ ] Subtitle system (load, display, customize)
- [ ] Playback position tracking
- [ ] Multi-audio track support
- [ ] Playback speed control (0.25x - 4x)

### Phase 3: Advanced Features (Week 5-6)
- [ ] Picture-in-Picture mode
- [ ] Background audio playback
- [ ] Network streaming (HLS/DASH)
- [ ] Auto-play next episode

### Phase 4: Polish (Week 7-8)
- [ ] Liquid animations
- [ ] Haptic feedback
- [ ] Lock screen mode
- [ ] Playlist viewer
- [ ] File browser enhancements

---

## 📱 Screen Wireframes

### Home Screen
```
┌─────────────────────────────┐
│  [≡]  Lumeo    [🔍] [⚙️]   │
├─────────────────────────────┤
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 📹  │ │ 📹  │ │ 📹  │   │
│  │Title│ │Title│ │Title│   │
│  └─────┘ └─────┘ └─────┘   │
│                             │
│  Continue Watching          │
│  ┌─────────────────────┐   │
│  │  [▶] Video Title    │   │
│  │  45:30 / 1:23:45   │   │
│  └─────────────────────┘   │
│                             │
│  Playlists                  │
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 📁  │ │ 📁  │ │ 📁  │   │
│  └─────┘ └─────┘ └─────┘   │
└─────────────────────────────┘
```

### Player Screen (Portrait)
```
┌─────────────────────────────┐
│  [←]  Video Title    [⋮]   │
├─────────────────────────────┤
│                             │
│                             │
│      [▶] Play Button        │
│                             │
│                             │
├─────────────────────────────┤
│  [━━━━━━━━━━━━━━━━━━━━]    │
│  00:45 / 1:23:45           │
│  [⏮] [⏯] [⏭] [🔊] [⚙️]    │
└─────────────────────────────┘
```

### Player Screen (Landscape)
```
┌─────────────────────────────────────────┐
│  [←] Title                    [⋮] [🔒] │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│              Video Player               │
│                                         │
│                                         │
│  [Subtitle Text Here]                   │
│                                         │
├─────────────────────────────────────────┤
│  [━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━]   │
│  [⏮] [⏯] [⏭] [🔊] [⚙️] [📱] [🔒]     │
└─────────────────────────────────────────┘
```

---

## 🔧 Key Implementation Files

### 1. Enhanced Video Player Page
Location: `lib/presentation/screens/video_player_page.dart`

Key enhancements needed:
- Gesture overlay integration
- Subtitle overlay
- Liquid controls
- Decoder switching UI
- Audio track selector
- Playback speed control

### 2. Subtitle Service
Location: `lib/core/services/subtitle_service.dart`

Features:
- Load local .srt, .ass, .vtt files
- Network subtitle fetching
- Auto-sync with delay adjustment
- Style customization
- Position dragging

### 3. Playback Position Service
Location: `lib/core/services/playback_position_service.dart`

Features:
- Save position on pause/exit
- Resume from last position
- Auto-save every 10 seconds
- Clear position option

---

## 🎯 Best Practices

1. **Performance**
   - Use hardware decoding by default
   - Lazy load video thumbnails
   - Cache subtitle files
   - Debounce gesture events

2. **User Experience**
   - Always show loading states
   - Provide haptic feedback
   - Smooth animations (60fps)
   - Clear error messages

3. **Code Quality**
   - Follow existing BLoC pattern
   - Use dependency injection
   - Write unit tests
   - Document complex logic

---

## 🚀 Next Steps

1. Review this blueprint
2. Prioritize features based on user needs
3. Start with Phase 1 (Foundation)
4. Iterate based on feedback
5. Add advanced features incrementally

---

## 📚 Additional Resources

- Better Player Docs: https://pub.dev/packages/better_player
- Flutter VLC Player: https://pub.dev/packages/flutter_vlc_player
- Glassmorphism Guide: https://glassmorphism.com/
- Flutter Animations: https://docs.flutter.dev/development/ui/animations

---

**Ready to build the future of video playback! 🚀**

