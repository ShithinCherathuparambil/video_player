import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/core/services/video_effects_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoEffectsService', () {
    late VideoEffectsService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = VideoEffectsService();
    });

    test('save, get, delete preset and current preset', () async {
      const presetName = 'MyPreset';
      final values = {
        'brightness': 1.2,
        'contrast': 1.1,
        'saturation': 0.9,
        'hue': 5.0,
        'gamma': 1.05,
      };

      await service.savePreset(presetName, values);
      final presets = await service.getPresets();
      expect(presets[presetName], values);

      await service.saveCurrentPreset(presetName);
      final current = await service.getCurrentPreset();
      expect(current, presetName);

      await service.deletePreset(presetName);
      final afterDelete = await service.getPresets();
      expect(afterDelete.containsKey(presetName), false);
    });
  });
}

