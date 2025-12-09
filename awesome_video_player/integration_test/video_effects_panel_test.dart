import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumeo/presentation/widgets/video_effects_panel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VideoEffectsPanel integration: filters, sliders, rotation',
      (tester) async {
    // Give ample space for scrollable content
    tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    double brightness = 1.0;
    double rotation = 0.0;
    String selectedFilter = 'None';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VideoEffectsPanel(
              brightness: brightness,
              contrast: 1.0,
              saturation: 1.0,
              hue: 0.0,
              gamma: 1.0,
              rotation: rotation,
              selectedFilter: selectedFilter,
              onBrightnessChanged: (v) => brightness = v,
              onContrastChanged: (_) {},
              onSaturationChanged: (_) {},
              onHueChanged: (_) {},
              onGammaChanged: (_) {},
              onFilterChanged: (f) => selectedFilter = f,
              onRotationChanged: (r) => rotation = r,
              onDeinterlaceChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    // Tap a filter and expect changes
    await tester.tap(find.text('Cinematic'));
    await tester.pumpAndSettle();
    expect(selectedFilter, 'Cinematic');
    expect(brightness, isNot(1.0));

    // Adjust brightness slider
    final brightnessSlider = find.byType(Slider).first;
    await tester.drag(brightnessSlider, const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(brightness, isNot(1.0));

    // Rotation
    await tester.ensureVisible(find.text('180°'));
    await tester.tap(find.text('180°'));
    await tester.pumpAndSettle();
    expect(rotation, 180.0);
  });
}

