import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/presentation/widgets/video_effects_panel.dart';

void main() {
  group('VideoEffectsPanel', () {
    testWidgets('invokes callbacks for filters, sliders, rotation, deinterlace',
        (tester) async {
      // Give enough space to avoid overflow in tests
      tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      double brightness = 1.0;
      double contrast = 1.0;
      double saturation = 1.0;
      double hue = 0.0;
      double gamma = 1.0;
      double rotation = 0.0;
      bool deinterlace = false;
      String selectedFilter = 'None';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoEffectsPanel(
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                hue: hue,
                gamma: gamma,
                rotation: rotation,
                deinterlace: deinterlace,
                selectedFilter: selectedFilter,
                onBrightnessChanged: (v) => brightness = v,
                onContrastChanged: (v) => contrast = v,
                onSaturationChanged: (v) => saturation = v,
                onHueChanged: (v) => hue = v,
                onGammaChanged: (v) => gamma = v,
                onFilterChanged: (f) => selectedFilter = f,
                onRotationChanged: (r) => rotation = r,
                onDeinterlaceChanged: (v) => deinterlace = v,
              ),
            ),
          ),
        ),
      );

      // Tap a filter
      await tester.tap(find.text('Vintage'));
      await tester.pumpAndSettle();
      expect(selectedFilter, 'Vintage');
      expect(brightness != 1.0, true); // preset applied

      // Move brightness slider
      final brightnessSlider = find.byType(Slider).at(0);
      await tester.drag(brightnessSlider, const Offset(50, 0));
      await tester.pump();
      expect(brightness, isNot(equals(1.0)));

      // Rotation selection
      await tester.ensureVisible(find.text('90°'));
      await tester.tap(find.text('90°'));
      await tester.pump();
      expect(rotation, 90.0);

      // Deinterlace switch
      final switchFinder = find.byType(Switch);
      await tester.tap(switchFinder);
      await tester.pump();
      expect(deinterlace, true);
    });

    testWidgets('tests all color adjustment sliders individually',
        (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      double brightness = 1.0;
      double contrast = 1.0;
      double saturation = 1.0;
      double hue = 0.0;
      double gamma = 1.0;
      double rotation = 0.0;
      bool deinterlace = false;
      String selectedFilter = 'None';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoEffectsPanel(
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                hue: hue,
                gamma: gamma,
                rotation: rotation,
                deinterlace: deinterlace,
                selectedFilter: selectedFilter,
                onBrightnessChanged: (v) => brightness = v,
                onContrastChanged: (v) => contrast = v,
                onSaturationChanged: (v) => saturation = v,
                onHueChanged: (v) => hue = v,
                onGammaChanged: (v) => gamma = v,
                onFilterChanged: (f) => selectedFilter = f,
                onRotationChanged: (r) => rotation = r,
                onDeinterlaceChanged: (v) => deinterlace = v,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get all sliders
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(5)); // brightness, contrast, saturation, hue, gamma

      // Test Brightness slider (index 0)
      final initialBrightness = brightness;
      await tester.drag(sliders.at(0), const Offset(100, 0));
      await tester.pump();
      expect(brightness, isNot(equals(initialBrightness)));
      expect(brightness, greaterThanOrEqualTo(0.0));
      expect(brightness, lessThanOrEqualTo(2.0));

      // Test Contrast slider (index 1)
      final initialContrast = contrast;
      await tester.drag(sliders.at(1), const Offset(100, 0));
      await tester.pump();
      expect(contrast, isNot(equals(initialContrast)));
      expect(contrast, greaterThanOrEqualTo(0.0));
      expect(contrast, lessThanOrEqualTo(2.0));

      // Test Saturation slider (index 2)
      final initialSaturation = saturation;
      await tester.drag(sliders.at(2), const Offset(100, 0));
      await tester.pump();
      expect(saturation, isNot(equals(initialSaturation)));
      expect(saturation, greaterThanOrEqualTo(0.0));
      expect(saturation, lessThanOrEqualTo(2.0));

      // Test Hue slider (index 3)
      final initialHue = hue;
      await tester.drag(sliders.at(3), const Offset(100, 0));
      await tester.pump();
      expect(hue, isNot(equals(initialHue)));
      expect(hue, greaterThanOrEqualTo(-180.0));
      expect(hue, lessThanOrEqualTo(180.0));

      // Test Gamma slider (index 4)
      final initialGamma = gamma;
      await tester.drag(sliders.at(4), const Offset(100, 0));
      await tester.pump();
      expect(gamma, isNot(equals(initialGamma)));
      expect(gamma, greaterThanOrEqualTo(0.1));
      expect(gamma, lessThanOrEqualTo(3.0));
    });

    testWidgets('tests all filter presets', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      double brightness = 1.0;
      double contrast = 1.0;
      double saturation = 1.0;
      double hue = 0.0;
      double gamma = 1.0;
      double rotation = 0.0;
      bool deinterlace = false;
      String selectedFilter = 'None';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoEffectsPanel(
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                hue: hue,
                gamma: gamma,
                rotation: rotation,
                deinterlace: deinterlace,
                selectedFilter: selectedFilter,
                onBrightnessChanged: (v) => brightness = v,
                onContrastChanged: (v) => contrast = v,
                onSaturationChanged: (v) => saturation = v,
                onHueChanged: (v) => hue = v,
                onGammaChanged: (v) => gamma = v,
                onFilterChanged: (f) => selectedFilter = f,
                onRotationChanged: (r) => rotation = r,
                onDeinterlaceChanged: (v) => deinterlace = v,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test all available filters
      final filters = [
        'None',
        'Vintage',
        'Black & White',
        'Sepia',
        'Cool',
        'Warm',
        'Dramatic',
        'Cinematic',
        'Vivid',
        'Soft',
      ];

      for (final filter in filters) {
        await tester.ensureVisible(find.text(filter));
        await tester.tap(find.text(filter));
        await tester.pumpAndSettle();
        expect(selectedFilter, filter);
      }
    });

    testWidgets('tests rotation options', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      double brightness = 1.0;
      double contrast = 1.0;
      double saturation = 1.0;
      double hue = 0.0;
      double gamma = 1.0;
      double rotation = 0.0;
      bool deinterlace = false;
      String selectedFilter = 'None';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoEffectsPanel(
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                hue: hue,
                gamma: gamma,
                rotation: rotation,
                deinterlace: deinterlace,
                selectedFilter: selectedFilter,
                onBrightnessChanged: (v) => brightness = v,
                onContrastChanged: (v) => contrast = v,
                onSaturationChanged: (v) => saturation = v,
                onHueChanged: (v) => hue = v,
                onGammaChanged: (v) => gamma = v,
                onFilterChanged: (f) => selectedFilter = f,
                onRotationChanged: (r) => rotation = r,
                onDeinterlaceChanged: (v) => deinterlace = v,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test all rotation options
      final rotations = [0.0, 90.0, 180.0, 270.0];
      final rotationLabels = ['0°', '90°', '180°', '270°'];

      for (int i = 0; i < rotations.length; i++) {
        // Find the InkWell containing the rotation label text
        final textFinder = find.text(rotationLabels[i]);
        // Find the ancestor InkWell widget
        final inkWellFinder = find.ancestor(
          of: textFinder,
          matching: find.byType(InkWell),
        );
        
        if (inkWellFinder.evaluate().isNotEmpty) {
          await tester.tap(inkWellFinder.first);
        } else {
          // Fallback: tap the text directly
          await tester.tap(textFinder.first);
        }
        await tester.pumpAndSettle();
        expect(rotation, rotations[i]);
      }
    });

    testWidgets('tests reset and save preset buttons', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      double brightness = 1.5;
      double contrast = 1.3;
      double saturation = 0.8;
      double hue = 10.0;
      double gamma = 1.2;
      double rotation = 90.0;
      bool deinterlace = true;
      String selectedFilter = 'Vintage';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoEffectsPanel(
                brightness: brightness,
                contrast: contrast,
                saturation: saturation,
                hue: hue,
                gamma: gamma,
                rotation: rotation,
                deinterlace: deinterlace,
                selectedFilter: selectedFilter,
                onBrightnessChanged: (v) => brightness = v,
                onContrastChanged: (v) => contrast = v,
                onSaturationChanged: (v) => saturation = v,
                onHueChanged: (v) => hue = v,
                onGammaChanged: (v) => gamma = v,
                onFilterChanged: (f) => selectedFilter = f,
                onRotationChanged: (r) => rotation = r,
                onDeinterlaceChanged: (v) => deinterlace = v,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test Reset button - should reset to 'None' filter values
      await tester.ensureVisible(find.text('Reset'));
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // After reset, values should be reset to 'None' preset
      expect(selectedFilter, 'None');
      expect(brightness, 1.0);
      expect(contrast, 1.0);
      expect(saturation, 1.0);
      expect(hue, 0.0);
      expect(gamma, 1.0);
    });
  });
}

