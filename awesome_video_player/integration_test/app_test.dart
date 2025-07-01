import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumeo/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Advanced app flow: open, play, favorite video',
      (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Wait for the video list to appear
    final videoListFinder = find.byType(ListView);
    expect(videoListFinder, findsWidgets);

    // Tap the first video card (assume ListTile or Card)
    final firstVideoFinder = find.byType(ListTile).first;
    expect(firstVideoFinder, findsOneWidget);
    await tester.tap(firstVideoFinder);
    await tester.pumpAndSettle();

    // Wait for the video player page (look for play icon or Chewie controls)
    final playButtonFinder = find.byIcon(Icons.play_arrow);
    expect(playButtonFinder, findsWidgets);
    await tester.tap(playButtonFinder.first);
    await tester.pumpAndSettle(const Duration(seconds: 2)); // Let video start

    // Go back to the video list
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Tap the favorite icon on the first video (assume IconButton with Icons.favorite)
    final favoriteButtonFinder = find.descendant(
      of: firstVideoFinder,
      matching: find.byIcon(Icons.favorite),
    );
    if (favoriteButtonFinder.evaluate().isNotEmpty) {
      await tester.tap(favoriteButtonFinder);
      await tester.pumpAndSettle();
    }

    // Check that the favorite icon is now filled (if your UI changes icon)
    // Optionally, navigate to favorites page and check for the video
    // final favoritesTabFinder = find.byIcon(Icons.favorite);
    // await tester.tap(favoritesTabFinder);
    // await tester.pumpAndSettle();
    // expect(find.textContaining('Video'), findsWidgets);
  });
}
