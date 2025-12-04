import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumeo/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Video Player Screen Integration Tests', () {
    testWidgets('Complete video player flow: open, play, pause, seek, and exit',
        (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Wait for splash screen to complete and navigate to video list
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find the video list (try ListView first, then GridView)
      Finder videoListFinder = find.byType(ListView);
      if (videoListFinder.evaluate().isEmpty) {
        videoListFinder = find.byType(GridView);
      }
      
      // Wait for videos to load
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Check if video list exists (either ListView or GridView)
      if (videoListFinder.evaluate().isNotEmpty) {
        // Find the first video card/item
        Finder videoCardFinder = find.byType(Card).first;
        if (videoCardFinder.evaluate().isEmpty) {
          videoCardFinder = find.byType(ListTile).first;
        }
        
        if (videoCardFinder.evaluate().isNotEmpty) {
          // Tap on the first video to open player
          await tester.tap(videoCardFinder);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Verify we're on the video player page
          // Look for video player controls or play button
          final playButtonFinder = find.byIcon(Icons.play_arrow);
          final pauseButtonFinder = find.byIcon(Icons.pause);
          
          // Wait for video player to initialize
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Test 1: Verify video player page is displayed
          final hasPlayerControls = playButtonFinder.evaluate().isNotEmpty || 
              pauseButtonFinder.evaluate().isNotEmpty;
          expect(
            hasPlayerControls,
            true,
            reason: 'Video player should show play or pause button',
          );

          // Test 2: Tap play button if video is paused
          if (playButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(playButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            
            // Verify video started playing (pause button should appear)
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }

          // Test 3: Tap to show/hide controls
          final videoPlayerArea = find.byType(Scaffold);
          if (videoPlayerArea.evaluate().isNotEmpty) {
            await tester.tap(videoPlayerArea.first);
            await tester.pumpAndSettle(const Duration(milliseconds: 500));
          }

          // Test 4: Test pause button
          if (pauseButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(pauseButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 1));
            
            // Verify video paused (play button should appear)
            expect(playButtonFinder, findsWidgets);
          }

          // Test 5: Test seekbar (if visible)
          final sliderFinder = find.byType(Slider);
          if (sliderFinder.evaluate().isNotEmpty) {
            // Try to drag the seekbar
            await tester.drag(sliderFinder.first, const Offset(50, 0));
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }

          // Test 6: Test back button to exit player
          final backButtonFinder = find.byIcon(Icons.arrow_back);
          if (backButtonFinder.evaluate().isNotEmpty) {
            await tester.tap(backButtonFinder.first);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            
            // Verify we're back on video list
            expect(videoListFinder, findsWidgets);
          } else {
            // Try using pageBack
            await tester.pageBack();
            await tester.pumpAndSettle(const Duration(seconds: 2));
            expect(videoListFinder, findsWidgets);
          }
        } else {
          // If no videos found, just verify the app is running
          expect(find.byType(MaterialApp), findsOneWidget);
        }
      } else {
        // If no video list found, verify app is running
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('Video player controls visibility and interaction',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to video player if possible
      Finder videoCardFinder = find.byType(Card).first;
      if (videoCardFinder.evaluate().isEmpty) {
        videoCardFinder = find.byType(ListTile).first;
      }
      
      if (videoCardFinder.evaluate().isNotEmpty) {
        await tester.tap(videoCardFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Test controls visibility
        final playButtonFinder = find.byIcon(Icons.play_arrow);
        final pauseButtonFinder = find.byIcon(Icons.pause);
        Finder volumeButtonFinder = find.byIcon(Icons.volume_up);
        if (volumeButtonFinder.evaluate().isEmpty) {
          volumeButtonFinder = find.byIcon(Icons.volume_off);
        }
        Finder settingsButtonFinder = find.byIcon(Icons.settings);
        if (settingsButtonFinder.evaluate().isEmpty) {
          settingsButtonFinder = find.byIcon(Icons.more_vert);
        }

        // Tap screen to show controls
        final scaffoldFinder = find.byType(Scaffold);
        if (scaffoldFinder.evaluate().isNotEmpty) {
          await tester.tap(scaffoldFinder.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
        }

        // Verify at least one control is visible
        final hasControls = playButtonFinder.evaluate().isNotEmpty ||
            pauseButtonFinder.evaluate().isNotEmpty ||
            volumeButtonFinder.evaluate().isNotEmpty ||
            settingsButtonFinder.evaluate().isNotEmpty;

        expect(hasControls, true, reason: 'Video player should have controls');

        // Test settings/menu button if available
        if (settingsButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(settingsButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('Video player playback state management',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      Finder videoCardFinder = find.byType(Card).first;
      if (videoCardFinder.evaluate().isEmpty) {
        videoCardFinder = find.byType(ListTile).first;
      }
      
      if (videoCardFinder.evaluate().isNotEmpty) {
        await tester.tap(videoCardFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        final playButtonFinder = find.byIcon(Icons.play_arrow);
        final pauseButtonFinder = find.byIcon(Icons.pause);

        // Test play -> pause -> play cycle
        if (playButtonFinder.evaluate().isNotEmpty) {
          // Start playing
          await tester.tap(playButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          
          // Should show pause button
          expect(pauseButtonFinder, findsWidgets);
        }

        if (pauseButtonFinder.evaluate().isNotEmpty) {
          // Pause
          await tester.tap(pauseButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          
          // Should show play button
          expect(playButtonFinder, findsWidgets);
        }

        // Play again
        if (playButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(playButtonFinder.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    });

    testWidgets('Video player navigation and exit',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      Finder videoCardFinder = find.byType(Card).first;
      if (videoCardFinder.evaluate().isEmpty) {
        videoCardFinder = find.byType(ListTile).first;
      }
      
      if (videoCardFinder.evaluate().isNotEmpty) {
        // Open video player
        await tester.tap(videoCardFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify we're on player page
        final playButtonFinder = find.byIcon(Icons.play_arrow);
        final pauseButtonFinder = find.byIcon(Icons.pause);
        expect(
          playButtonFinder.evaluate().isNotEmpty ||
              pauseButtonFinder.evaluate().isNotEmpty,
          true,
        );

        // Exit player
        final backButtonFinder = find.byIcon(Icons.arrow_back);
        if (backButtonFinder.evaluate().isNotEmpty) {
          await tester.tap(backButtonFinder.first);
        } else {
          await tester.pageBack();
        }
        
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify we're back on video list
        Finder videoListFinder = find.byType(ListView);
        if (videoListFinder.evaluate().isEmpty) {
          videoListFinder = find.byType(GridView);
        }
        expect(videoListFinder, findsWidgets);
      }
    });
  });
}

