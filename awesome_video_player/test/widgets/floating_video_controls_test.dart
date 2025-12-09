import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:lumeo/presentation/widgets/floating_video_controls.dart';

void main() {
  group('FloatingVideoControls', () {
    Future<void> _pumpControls(WidgetTester tester,
        {required VoidCallback onHardwareToggle,
        required VoidCallback onVideoEffects,
        required VoidCallback onPip,
        required VoidCallback onBookmarks,
        required ValueChanged<String> onAudioTrackChanged,
        required ValueChanged<String> onSubtitleTrackChanged}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingVideoControls(
              position: Duration.zero,
              duration: const Duration(minutes: 2),
              onTogglePlayPause: () {},
              isPlaying: false,
              showControls: true,
              onOpenEqualizer: () {},
              onOpenVideoEffects: onVideoEffects,
              hasVideoEffects: true,
              onOpenAdvancedFeatures: () {},
              onEnterPip: onPip,
              onOpenFitModeSelector: () {},
              onSeekForward: () {},
              onSeekBackward: () {},
              onToggleStatistics: () {},
              onOpenPlaylist: () {},
              onOpenChapters: () {},
              onBookmarksTap: onBookmarks,
              onPlaybackSpeedChanged: (_) {},
              playbackSpeed: 1.0,
              showStatistics: false,
              hardwareAcceleration: true,
              deinterlace: false,
              frameDrop: true,
              networkCaching: true,
              networkCacheSize: 1000,
              audioSync: true,
              audioDelay: 0,
              subtitleDelay: 0,
              showTimeRemaining: true,
              showBuffering: true,
              showQuality: true,
              rememberPosition: true,
              autoPlayNext: true,
              shuffleEnabled: false,
              selectedQuality: 'Auto',
              selectedAudioTrack: 'Track 1',
              selectedSubtitleTrack: 'English',
              selectedVideoTrack: 'Default',
              backgroundPlayEnabled: false,
              loopMode: 'Off',
              availableAudioTracks: const ['Track 1'],
              availableSubtitleTracks: const ['English'],
              ambientModeEnabled: false,
              onAmbientModeChanged: (_) {},
              onHardwareAccelerationChanged: (_) => onHardwareToggle(),
              onDeinterlaceChanged: (_) {},
              onFrameDropChanged: (_) {},
              onNetworkCachingChanged: (_) {},
              onNetworkCacheSizeChanged: (_) {},
              onAudioSyncChanged: (_) {},
              onAudioDelayChanged: (_) {},
              onSubtitleDelayChanged: (_) {},
              onShowTimeRemainingChanged: (_) {},
              onShowBufferingChanged: (_) {},
              onShowQualityChanged: (_) {},
              onRememberPositionChanged: (_) {},
              onAutoPlayNextChanged: (_) {},
              onShuffleEnabledChanged: (_) {},
              onQualityChanged: (_) {},
              onAudioTrackChanged: onAudioTrackChanged,
              onSubtitleTrackChanged: onSubtitleTrackChanged,
              onVideoTrackChanged: (_) {},
              onBackgroundPlayEnabledChanged: (_) {},
              onLoopModeChanged: (_) {},
              title: 'Test Video',
            ),
          ),
        ),
      );
    }

    testWidgets('invokes primary controls callbacks', (tester) async {
      var hardwareToggled = 0;
      var effectsOpened = 0;
      var pipOpened = 0;
      var bookmarksOpened = 0;
      String? selectedAudio;
      String? selectedSubtitle;

      await _pumpControls(
        tester,
        onHardwareToggle: () => hardwareToggled++,
        onVideoEffects: () => effectsOpened++,
        onPip: () => pipOpened++,
        onBookmarks: () => bookmarksOpened++,
        onAudioTrackChanged: (track) => selectedAudio = track,
        onSubtitleTrackChanged: (track) => selectedSubtitle = track,
      );

      // Hardware/Software toggle
      await tester.tap(find.byIcon(LucideIcons.cpu));
      await tester.pump();
      expect(hardwareToggled, 1);

      // Video effects
      await tester.tap(find.byIcon(LucideIcons.sliders));
      await tester.pump();
      expect(effectsOpened, 1);

      // PiP
      await tester.tap(find.byIcon(LucideIcons.pictureInPicture));
      await tester.pump();
      expect(pipOpened, 1);

      // Bookmarks
      await tester.tap(find.byIcon(LucideIcons.bookmark));
      await tester.pump();
      expect(bookmarksOpened, 1);

      // Audio track selection
      await tester.tap(find.byIcon(LucideIcons.music));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Track 1'));
      await tester.pumpAndSettle();
      expect(selectedAudio, 'Track 1');

      // Subtitle track selection
      await tester.tap(find.byIcon(LucideIcons.subtitles));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(selectedSubtitle, 'English');
    });
  });
}

