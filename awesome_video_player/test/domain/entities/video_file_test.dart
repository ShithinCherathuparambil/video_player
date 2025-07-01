import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import '../../helpers/test_data_builders.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('VideoFile Entity Tests', () {
    late VideoFile testVideoFile;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2023, 1, 1);
      testVideoFile = VideoFileBuilder()
          .withPath(TestConstants.testVideoPath)
          .withName(TestConstants.testVideoName)
          .withThumbnailPath(TestConstants.testThumbnailPath)
          .withDuration(TestConstants.mediumDuration)
          .withFileSize(TestConstants.mediumFileSize)
          .withDateAdded(testDate)
          .build();
    });

    group('Constructor Tests', () {
      test('should create VideoFile with required parameters', () {
        final videoFile = VideoFile(
          path: TestConstants.testVideoPath,
          name: TestConstants.testVideoName,
        );

        expect(videoFile.path, TestConstants.testVideoPath);
        expect(videoFile.name, TestConstants.testVideoName);
        expect(videoFile.status, VideoStatus.new_);
        expect(videoFile.isFavorite, false);
        expect(videoFile.thumbnailPath, null);
        expect(videoFile.duration, null);
        expect(videoFile.fileSize, null);
        expect(videoFile.dateAdded, null);
        expect(videoFile.lastPlayedPosition, null);
        expect(videoFile.lastPlayedAt, null);
      });

      test('should create VideoFile with all parameters', () {
        expect(testVideoFile.path, TestConstants.testVideoPath);
        expect(testVideoFile.name, TestConstants.testVideoName);
        expect(testVideoFile.thumbnailPath, TestConstants.testThumbnailPath);
        expect(testVideoFile.duration, TestConstants.mediumDuration);
        expect(testVideoFile.fileSize, TestConstants.mediumFileSize);
        expect(testVideoFile.dateAdded, testDate);
        expect(testVideoFile.status, VideoStatus.new_);
        expect(testVideoFile.isFavorite, false);
      });
    });

    group('Equality Tests', () {
      test('should be equal when all properties are the same', () {
        final videoFile1 = VideoFileBuilder()
            .withPath(TestConstants.testVideoPath)
            .withName(TestConstants.testVideoName)
            .build();

        final videoFile2 = VideoFileBuilder()
            .withPath(TestConstants.testVideoPath)
            .withName(TestConstants.testVideoName)
            .build();

        expect(videoFile1, equals(videoFile2));
        expect(videoFile1.hashCode, equals(videoFile2.hashCode));
      });

      test('should not be equal when paths are different', () {
        final videoFile1 = VideoFileBuilder()
            .withPath(TestConstants.testVideoPath)
            .withName(TestConstants.testVideoName)
            .build();

        final videoFile2 = VideoFileBuilder()
            .withPath(TestConstants.testVideoPath2)
            .withName(TestConstants.testVideoName)
            .build();

        expect(videoFile1, isNot(equals(videoFile2)));
        expect(videoFile1.hashCode, isNot(equals(videoFile2.hashCode)));
      });

      test('should not be equal when names are different', () {
        final videoFile1 = VideoFileBuilder()
            .withPath(TestConstants.testVideoPath)
            .withName(TestConstants.testVideoName)
            .build();

        final videoFile2 = VideoFileBuilder()
            .withPath(TestConstants.testVideoPath)
            .withName(TestConstants.testVideoName2)
            .build();

        expect(videoFile1, isNot(equals(videoFile2)));
      });
    });

    group('CopyWith Tests', () {
      test('should return same object when no parameters provided', () {
        final copiedVideoFile = testVideoFile.copyWith();

        expect(copiedVideoFile, equals(testVideoFile));
        expect(copiedVideoFile.path, testVideoFile.path);
        expect(copiedVideoFile.name, testVideoFile.name);
        expect(copiedVideoFile.thumbnailPath, testVideoFile.thumbnailPath);
        expect(copiedVideoFile.duration, testVideoFile.duration);
        expect(copiedVideoFile.fileSize, testVideoFile.fileSize);
        expect(copiedVideoFile.dateAdded, testVideoFile.dateAdded);
        expect(copiedVideoFile.status, testVideoFile.status);
        expect(copiedVideoFile.isFavorite, testVideoFile.isFavorite);
      });

      test('should update only specified parameters', () {
        const newName = 'Updated Video Name';
        const newStatus = VideoStatus.watched;
        const newIsFavorite = true;

        final copiedVideoFile = testVideoFile.copyWith(
          name: newName,
          status: newStatus,
          isFavorite: newIsFavorite,
        );

        expect(copiedVideoFile.name, newName);
        expect(copiedVideoFile.status, newStatus);
        expect(copiedVideoFile.isFavorite, newIsFavorite);
        // Other properties should remain the same
        expect(copiedVideoFile.path, testVideoFile.path);
        expect(copiedVideoFile.thumbnailPath, testVideoFile.thumbnailPath);
        expect(copiedVideoFile.duration, testVideoFile.duration);
        expect(copiedVideoFile.fileSize, testVideoFile.fileSize);
        expect(copiedVideoFile.dateAdded, testVideoFile.dateAdded);
      });

      test('should update playback information', () {
        final newLastPlayedAt = DateTime.now();
        const newLastPlayedPosition = Duration(minutes: 10);

        final copiedVideoFile = testVideoFile.copyWith(
          lastPlayedAt: newLastPlayedAt,
          lastPlayedPosition: newLastPlayedPosition,
          status: VideoStatus.watching,
        );

        expect(copiedVideoFile.lastPlayedAt, newLastPlayedAt);
        expect(copiedVideoFile.lastPlayedPosition, newLastPlayedPosition);
        expect(copiedVideoFile.status, VideoStatus.watching);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        final json = testVideoFile.toJson();

        expect(json['path'], TestConstants.testVideoPath);
        expect(json['name'], TestConstants.testVideoName);
        expect(json['thumbnailPath'], TestConstants.testThumbnailPath);
        expect(json['duration'], TestConstants.mediumDuration.inMilliseconds);
        expect(json['fileSize'], TestConstants.mediumFileSize);
        expect(json['dateAdded'], testDate.millisecondsSinceEpoch);
        expect(json['lastPlayedPosition'], 0); // Duration.zero
        expect(json['lastPlayedAt'], null);
        expect(json['status'], VideoStatus.new_.index);
        expect(json['isFavorite'], false);
      });

      test('should serialize to JSON with null values', () {
        final videoFile = VideoFile(
          path: TestConstants.testVideoPath,
          name: TestConstants.testVideoName,
        );

        final json = videoFile.toJson();

        expect(json['path'], TestConstants.testVideoPath);
        expect(json['name'], TestConstants.testVideoName);
        expect(json['thumbnailPath'], null);
        expect(json['duration'], null);
        expect(json['fileSize'], null);
        expect(json['dateAdded'], null);
        expect(json['lastPlayedPosition'], null);
        expect(json['lastPlayedAt'], null);
        expect(json['status'], VideoStatus.new_.index);
        expect(json['isFavorite'], false);
      });

      test('should deserialize from JSON correctly', () {
        final json = testVideoFile.toJson();
        final deserializedVideoFile = VideoFile.fromJson(json);

        expect(deserializedVideoFile, equals(testVideoFile));
        expect(deserializedVideoFile.path, testVideoFile.path);
        expect(deserializedVideoFile.name, testVideoFile.name);
        expect(
            deserializedVideoFile.thumbnailPath, testVideoFile.thumbnailPath);
        expect(deserializedVideoFile.duration, testVideoFile.duration);
        expect(deserializedVideoFile.fileSize, testVideoFile.fileSize);
        expect(deserializedVideoFile.dateAdded, testVideoFile.dateAdded);
        expect(deserializedVideoFile.status, testVideoFile.status);
        expect(deserializedVideoFile.isFavorite, testVideoFile.isFavorite);
      });

      test('should deserialize from JSON with null values', () {
        final json = {
          'path': TestConstants.testVideoPath,
          'name': TestConstants.testVideoName,
          'thumbnailPath': null,
          'duration': null,
          'fileSize': null,
          'dateAdded': null,
          'lastPlayedPosition': null,
          'lastPlayedAt': null,
          'status': null,
          'isFavorite': false,
        };

        final videoFile = VideoFile.fromJson(json);

        expect(videoFile.path, TestConstants.testVideoPath);
        expect(videoFile.name, TestConstants.testVideoName);
        expect(videoFile.thumbnailPath, null);
        expect(videoFile.duration, null);
        expect(videoFile.fileSize, null);
        expect(videoFile.dateAdded, null);
        expect(videoFile.lastPlayedPosition, null);
        expect(videoFile.lastPlayedAt, null);
        expect(videoFile.status, VideoStatus.new_); // Default value
        expect(videoFile.isFavorite, false);
      });

      test('should handle round-trip serialization', () {
        final json = testVideoFile.toJson();
        final deserializedVideoFile = VideoFile.fromJson(json);
        final reserializedJson = deserializedVideoFile.toJson();

        expect(reserializedJson, equals(json));
      });
    });

    group('VideoStatus Enum Tests', () {
      test('should have correct enum values', () {
        expect(VideoStatus.values.length, 4);
        expect(VideoStatus.values, contains(VideoStatus.new_));
        expect(VideoStatus.values, contains(VideoStatus.watching));
        expect(VideoStatus.values, contains(VideoStatus.watched));
        expect(VideoStatus.values, contains(VideoStatus.lastWatched));
      });

      test('should serialize enum correctly', () {
        expect(VideoStatus.new_.index, 0);
        expect(VideoStatus.watched.index, 1);
        expect(VideoStatus.watching.index, 2);
        expect(VideoStatus.lastWatched.index, 3);
      });
    });

    group('Business Logic Tests', () {
      test('should identify new videos correctly', () {
        final newVideo =
            VideoFileBuilder().withStatus(VideoStatus.new_).build();

        expect(newVideo.status, VideoStatus.new_);
        expect(newVideo.lastPlayedAt, null);
        expect(newVideo.lastPlayedPosition, Duration.zero);
      });

      test('should identify partially watched videos correctly', () {
        final partiallyWatchedVideo =
            VideoFileBuilder().asPartiallyWatched().build();

        expect(partiallyWatchedVideo.status, VideoStatus.watching);
        expect(partiallyWatchedVideo.lastPlayedAt, isNotNull);
        expect(partiallyWatchedVideo.lastPlayedPosition, isNotNull);
        expect(partiallyWatchedVideo.lastPlayedPosition!.inMilliseconds,
            greaterThan(0));
      });

      test('should identify watched videos correctly', () {
        final watchedVideo = VideoFileBuilder().asWatched().build();

        expect(watchedVideo.status, VideoStatus.watched);
        expect(watchedVideo.lastPlayedAt, isNotNull);
        expect(watchedVideo.lastPlayedPosition, isNotNull);
      });

      test('should handle favorite status correctly', () {
        final favoriteVideo = VideoFileBuilder().asFavorite().build();

        final nonFavoriteVideo = VideoFileBuilder().asNotFavorite().build();

        expect(favoriteVideo.isFavorite, true);
        expect(nonFavoriteVideo.isFavorite, false);
      });
    });
  });
}
