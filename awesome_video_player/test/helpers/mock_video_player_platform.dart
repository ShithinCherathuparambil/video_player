import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock video player platform for testing
/// This sets up method channel mocking for video player
class MockVideoPlayerPlatform {
  static void registerWith() {
    // Set up method channel mocking for video player
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.io/videoPlayer'),
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'init':
            return null;
          case 'create':
            return {'textureId': 1};
          case 'setLooping':
          case 'setVolume':
          case 'setPlaybackSpeed':
          case 'play':
          case 'pause':
          case 'seekTo':
          case 'dispose':
            return null;
          case 'getPosition':
            return {'position': 0};
          default:
            return null;
        }
      },
    );
  }

  static Widget buildMockVideoView() {
    // Return a simple container for testing
    return Container(
      width: 300,
      height: 200,
      color: const Color(0xFF000000),
      child: const Center(
        child: Text(
          'Mock Video Player',
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
    );
  }
}
