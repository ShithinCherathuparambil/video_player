import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/core/extensions/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    group('toPng', () {
      test('should return correct PNG image path', () {
        expect('logo'.toPng, equals('assets/images/logo.png'));
        expect('icon_play'.toPng, equals('assets/images/icon_play.png'));
        expect('splash_background'.toPng, equals('assets/images/splash_background.png'));
      });

      test('should handle empty string', () {
        expect(''.toPng, equals('assets/images/.png'));
      });

      test('should handle special characters', () {
        expect('icon-play_button'.toPng, equals('assets/images/icon-play_button.png'));
      });
    });

    group('toImage', () {
      test('should return correct image path with custom extension', () {
        expect('logo'.toImage('jpg'), equals('assets/images/logo.jpg'));
        expect('icon'.toImage('svg'), equals('assets/images/icon.svg'));
        expect('background'.toImage('webp'), equals('assets/images/background.webp'));
      });

      test('should handle empty extension', () {
        expect('logo'.toImage(''), equals('assets/images/logo.'));
      });
    });

    group('toIcon', () {
      test('should return correct icon path', () {
        expect('play'.toIcon, equals('assets/icons/play.png'));
        expect('pause'.toIcon, equals('assets/icons/pause.png'));
        expect('stop'.toIcon, equals('assets/icons/stop.png'));
      });
    });

    group('toIconImage', () {
      test('should return correct icon path with custom extension', () {
        expect('play'.toIconImage('svg'), equals('assets/icons/play.svg'));
        expect('pause'.toIconImage('jpg'), equals('assets/icons/pause.jpg'));
      });
    });

    group('toAsset', () {
      test('should return correct asset path', () {
        expect('data.json'.toAsset, equals('assets/data.json'));
        expect('config.yaml'.toAsset, equals('assets/config.yaml'));
        expect('readme.txt'.toAsset, equals('assets/readme.txt'));
      });
    });

    group('toAssetFolder', () {
      test('should return correct asset path in custom folder', () {
        expect('video.mp4'.toAssetFolder('videos'), equals('assets/videos/video.mp4'));
        expect('font.ttf'.toAssetFolder('fonts'), equals('assets/fonts/font.ttf'));
        expect('sound.wav'.toAssetFolder('audio'), equals('assets/audio/sound.wav'));
      });

      test('should handle nested folders', () {
        expect('file.txt'.toAssetFolder('data/config'), equals('assets/data/config/file.txt'));
      });
    });
  });
}
