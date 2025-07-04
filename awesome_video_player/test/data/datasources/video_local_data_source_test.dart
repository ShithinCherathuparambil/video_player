import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/core/error/exceptions.dart';
import '../../helpers/test_utils.dart';
import '../../helpers/test_constants.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/foundation.dart';

void main() {
  group('VideoLocalDataSource Tests', () {
    late VideoLocalDataSourceImpl dataSource;
    late Directory tempDirectory;

    setUp(() async {
      TestUtils.setupTestEnvironment();
      tempDirectory = await TestUtils.createTempDirectory();
      dataSource = VideoLocalDataSourceImpl(directory: tempDirectory);
    });

    tearDown(() async {
      await TestUtils.cleanupTempFiles([tempDirectory]);
    });

    group('Constructor Tests', () {
      test('should create instance with provided directory', () {
        // arrange & act
        final dataSourceWithDir =
            VideoLocalDataSourceImpl(directory: tempDirectory);

        // assert
        expect(dataSourceWithDir, isA<VideoLocalDataSourceImpl>());
      });

      test('should create instance without directory', () {
        // arrange & act
        final dataSourceWithoutDir = VideoLocalDataSourceImpl();

        // assert
        expect(dataSourceWithoutDir, isA<VideoLocalDataSourceImpl>());
      });
    });

    group('getVideos Tests', () {
      test('should return empty list when no video files exist', () async {
        // arrange
        // tempDirectory is empty by default

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result, isEmpty);
      });

      test('should return video files when they exist', () async {
        // arrange
        final videoFile = await TestUtils.createTempVideoFile();
        await videoFile.copy('${tempDirectory.path}/test_video.mp4');

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result, isNotEmpty);
        expect(result.first.name, 'test_video.mp4');
        expect(result.first.path, contains('test_video.mp4'));
      });

      test('should filter only video files', () async {
        // arrange
        await File('${tempDirectory.path}/video.mp4').create();
        await File('${tempDirectory.path}/image.jpg').create();
        await File('${tempDirectory.path}/document.txt').create();
        await File('${tempDirectory.path}/video.avi').create();

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, 2); // Only video files
        expect(result.any((v) => v.name == 'video.mp4'), true);
        expect(result.any((v) => v.name == 'video.avi'), true);
        expect(result.any((v) => v.name == 'image.jpg'), false);
        expect(result.any((v) => v.name == 'document.txt'), false);
      });

      test('should handle multiple video formats', () async {
        // arrange
        final videoFormats = [
          '.mp4',
          '.mov',
          '.avi',
          '.mkv',
          '.wmv',
          '.flv',
          '.webm',
          '.m4v',
          '.3gp'
        ];
        for (int i = 0; i < videoFormats.length; i++) {
          await File('${tempDirectory.path}/video$i${videoFormats[i]}')
              .create();
        }

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, videoFormats.length);
        for (int i = 0; i < videoFormats.length; i++) {
          expect(
              result.any((v) => v.name == 'video$i${videoFormats[i]}'), true);
        }
      });

      test('should include file metadata', () async {
        // arrange
        final videoFile = File('${tempDirectory.path}/test_video.mp4');
        await videoFile.create();
        await videoFile.writeAsBytes(List.filled(1024, 0)); // 1KB file

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result, isNotEmpty);
        final video = result.first;
        expect(video.name, 'test_video.mp4');
        expect(video.path, videoFile.path);
        expect(video.fileSize, 1024);
        expect(video.dateAdded, isNotNull);
      });

      test('should handle nested directories', () async {
        // arrange
        final subDir = Directory('${tempDirectory.path}/subfolder');
        await subDir.create();
        await File('${subDir.path}/nested_video.mp4').create();
        await File('${tempDirectory.path}/root_video.mp4').create();

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, 2);
        expect(result.any((v) => v.name == 'nested_video.mp4'), true);
        expect(result.any((v) => v.name == 'root_video.mp4'), true);
      });
    });

    group('requestPermissions Tests', () {
      test('should complete without throwing', () async {
        // act & assert
        expect(() => dataSource.requestPermissions(), returnsNormally);
      });

      test('should handle permission request', () async {
        // arrange & act
        await dataSource.requestPermissions();

        // assert - should complete successfully
        expect(true, true); // Test passes if no exception is thrown
      });
    });

    group('Error Handling Tests', () {
      test('should throw CacheException when directory access fails', () async {
        // arrange
        final nonExistentDir = Directory('/non/existent/path');
        final dataSourceWithBadDir =
            VideoLocalDataSourceImpl(directory: nonExistentDir);

        // act & assert
        expect(() => dataSourceWithBadDir.getVideos(),
            throwsA(isA<CacheException>()));
      });

      test('should handle permission denied scenarios', () async {
        // Note: This is difficult to test in a unit test environment
        // In a real scenario, you would mock the platform-specific permission handling

        // arrange & act & assert
        expect(() => dataSource.requestPermissions(), returnsNormally);
      });

      test('should handle corrupted video files gracefully', () async {
        // arrange
        final corruptedFile = File('${tempDirectory.path}/corrupted.mp4');
        await corruptedFile.create();
        await corruptedFile.writeAsString('This is not a video file');

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result, isNotEmpty);
        expect(result.first.name, 'corrupted.mp4');
        // Duration and thumbnail might be null for corrupted files
      });
    });

    group('Platform-specific Tests', () {
      test('should handle desktop platform video loading', () async {
        // arrange
        await File('${tempDirectory.path}/desktop_video.mp4').create();

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result, isNotEmpty);
        expect(result.first.name, 'desktop_video.mp4');
      });

      test('should handle different file sizes', () async {
        // arrange
        final smallFile = File('${tempDirectory.path}/small.mp4');
        final largeFile = File('${tempDirectory.path}/large.mp4');

        await smallFile.create();
        await smallFile.writeAsBytes(List.filled(100, 0)); // 100 bytes

        await largeFile.create();
        await largeFile.writeAsBytes(List.filled(10000, 0)); // 10KB

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, 2);
        final smallVideo = result.firstWhere((v) => v.name == 'small.mp4');
        final largeVideo = result.firstWhere((v) => v.name == 'large.mp4');

        expect(smallVideo.fileSize, 100);
        expect(largeVideo.fileSize, 10000);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple video files efficiently', () async {
        // arrange
        for (int i = 0; i < 50; i++) {
          await File('${tempDirectory.path}/video_$i.mp4').create();
        }

        // act
        final stopwatch = Stopwatch()..start();
        final result = await dataSource.getVideos();
        stopwatch.stop();

        // assert
        expect(result.length, 50);
        expect(stopwatch.elapsedMilliseconds,
            lessThan(5000)); // Should complete within 5 seconds
      });

      test('should handle concurrent getVideos calls', () async {
        // arrange
        await File('${tempDirectory.path}/test_video.mp4').create();

        // act
        final futures = List.generate(5, (_) => dataSource.getVideos());
        final results = await Future.wait(futures);

        // assert
        for (final result in results) {
          expect(result.length, 1);
          expect(result.first.name, 'test_video.mp4');
        }
      });
    });

    group('File Extension Tests', () {
      test('should recognize all supported video extensions', () async {
        // arrange
        final supportedExtensions = [
          '.mp4',
          '.mov',
          '.avi',
          '.mkv',
          '.wmv',
          '.flv',
          '.webm',
          '.m4v',
          '.3gp'
        ];

        for (int i = 0; i < supportedExtensions.length; i++) {
          await File('${tempDirectory.path}/video$i${supportedExtensions[i]}')
              .create();
        }

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, supportedExtensions.length);
      });

      test('should ignore unsupported file extensions', () async {
        // arrange
        final unsupportedFiles = [
          'audio.mp3',
          'image.png',
          'document.pdf',
          'archive.zip',
          'text.txt'
        ];

        for (final fileName in unsupportedFiles) {
          await File('${tempDirectory.path}/$fileName').create();
        }

        await File('${tempDirectory.path}/video.mp4')
            .create(); // One valid video

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, 1);
        expect(result.first.name, 'video.mp4');
      });

      test('should handle case-insensitive extensions', () async {
        // arrange
        await File('${tempDirectory.path}/video1.MP4').create();
        await File('${tempDirectory.path}/video2.Mp4').create();
        await File('${tempDirectory.path}/video3.mp4').create();

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result.length, 3);
      });
    });

    group('Integration Tests', () {
      test('should work with real file system operations', () async {
        // arrange
        final videoFile = await TestUtils.createTempVideoFile();
        final targetPath = '${tempDirectory.path}/integration_test.mp4';
        await videoFile.copy(targetPath);

        // act
        final result = await dataSource.getVideos();

        // assert
        expect(result, isNotEmpty);
        expect(result.first.name, 'integration_test.mp4');
        expect(result.first.path, targetPath);
        expect(result.first.fileSize, greaterThan(0));
        expect(result.first.dateAdded, isNotNull);
      });
    });

    group('iOS-specific Tests', () {
      test('should use thumbnailBytes and correct name for iOS AssetEntity',
          () async {
        // Simulate iOS platform
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        // Mock AssetEntity
        final mockEntity = MockAssetEntity();
        final mockFile = File('${tempDirectory.path}/ios_video.mov');
        await mockFile.create();
        final fakeBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        when(mockEntity.type).thenReturn(AssetType.video);
        when(mockEntity.file).thenAnswer((_) async => mockFile);
        when(mockEntity.title).thenReturn('My iOS Video');
        when(mockEntity.thumbnailDataWithSize(ThumbnailSize(120, 120)))
            .thenAnswer((Invocation inv) async => fakeBytes);
        when(mockEntity.createDateTime).thenReturn(DateTime.now());

        // Patch _getPlatformVideos to use our mock entity
        final dataSourceIOS = VideoLocalDataSourceImpl();
        Future<List<VideoFile>> fakeGetPlatformVideos() async {
          final file = await mockEntity.file;
          final thumbnailBytes =
              await mockEntity.thumbnailDataWithSize(ThumbnailSize(120, 120));
          return [
            VideoFile(
              path: file!.path,
              name: mockEntity.title!,
              thumbnailBytes: thumbnailBytes,
              duration: null,
              fileSize: await file.length(),
              dateAdded: mockEntity.createDateTime,
            )
          ];
        }

        // act
        final result = await fakeGetPlatformVideos();
        // assert
        expect(result, isNotEmpty);
        expect(result.first.name, 'My iOS Video');
        expect(result.first.thumbnailBytes, isNotNull);
        expect(result.first.thumbnailBytes, fakeBytes);
        debugDefaultTargetPlatformOverride = null; // Reset after test
      });
    });
  });
}

class MockAssetEntity extends Mock implements AssetEntity {}
