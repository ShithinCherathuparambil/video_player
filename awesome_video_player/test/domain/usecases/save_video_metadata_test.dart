import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/domain/entities/video_file.dart';

import 'package:lumeo/domain/usecases/save_video_metadata.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('SaveVideoMetadata Use Case Tests', () {
    late SaveVideoMetadata usecase;
    late MockVideoRepository mockVideoRepository;
    late VideoFile testVideoFile;

    setUp(() {
      mockVideoRepository = MockFactories.createMockVideoRepository();
      usecase = SaveVideoMetadata(mockVideoRepository);
      testVideoFile = VideoFileBuilder()
          .withPath(TestConstants.testVideoPath)
          .withName(TestConstants.testVideoName)
          .withDuration(TestConstants.mediumDuration)
          .withFileSize(TestConstants.mediumFileSize)
          .build();
    });

    group('Successful Execution Tests', () {
      test('should save video metadata through repository', () async {
        // arrange
        when(mockVideoRepository.saveVideoMetadata(testVideoFile))
            .thenAnswer((_) async {});

        // act
        await usecase.call(testVideoFile);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(testVideoFile)).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should save video with updated playback position', () async {
        // arrange
        final videoWithPosition = testVideoFile.copyWith(
          lastPlayedPosition: const Duration(minutes: 10),
          lastPlayedAt: DateTime.now(),
          status: VideoStatus.watching,
        );
        when(mockVideoRepository.saveVideoMetadata(videoWithPosition))
            .thenAnswer((_) async {});

        // act
        await usecase.call(videoWithPosition);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(videoWithPosition))
            .called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should save video with favorite status', () async {
        // arrange
        final favoriteVideo = testVideoFile.copyWith(isFavorite: true);
        when(mockVideoRepository.saveVideoMetadata(favoriteVideo))
            .thenAnswer((_) async {});

        // act
        await usecase.call(favoriteVideo);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(favoriteVideo)).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should save video with watched status', () async {
        // arrange
        final watchedVideo = testVideoFile.copyWith(
          status: VideoStatus.watched,
          lastPlayedPosition: testVideoFile.duration,
          lastPlayedAt: DateTime.now(),
        );
        when(mockVideoRepository.saveVideoMetadata(watchedVideo))
            .thenAnswer((_) async {});

        // act
        await usecase.call(watchedVideo);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(watchedVideo)).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });
    });

    group('Error Handling Tests', () {
      test('should propagate repository exceptions', () async {
        // arrange
        final exception = Exception('Save failed');
        when(mockVideoRepository.saveVideoMetadata(testVideoFile))
            .thenThrow(exception);

        // act & assert
        expect(() => usecase.call(testVideoFile), throwsA(exception));
        verify(mockVideoRepository.saveVideoMetadata(testVideoFile)).called(1);
      });

      test('should propagate storage exceptions', () async {
        // arrange
        final storageException = Exception('Storage full');
        when(mockVideoRepository.saveVideoMetadata(testVideoFile))
            .thenThrow(storageException);

        // act & assert
        expect(() => usecase.call(testVideoFile), throwsA(storageException));
        verify(mockVideoRepository.saveVideoMetadata(testVideoFile)).called(1);
      });

      test('should propagate permission exceptions', () async {
        // arrange
        final permissionException = Exception('Permission denied');
        when(mockVideoRepository.saveVideoMetadata(testVideoFile))
            .thenThrow(permissionException);

        // act & assert
        expect(() => usecase.call(testVideoFile), throwsA(permissionException));
        verify(mockVideoRepository.saveVideoMetadata(testVideoFile)).called(1);
      });
    });

    group('Data Integrity Tests', () {
      test('should preserve all video file properties during save', () async {
        // arrange
        final complexVideo = VideoFileBuilder()
            .withPath('/complex/video.mp4')
            .withName('Complex Video')
            .withThumbnailPath('/complex/thumbnail.jpg')
            .withDuration(const Duration(hours: 2, minutes: 30))
            .withFileSize(5000000000) // 5GB
            .withDateAdded(DateTime(2023, 6, 15))
            .withLastPlayedPosition(const Duration(minutes: 45))
            .withLastPlayedAt(DateTime(2023, 6, 20))
            .withLastPlayedAt(DateTime(2023, 6, 20))
            .withStatus(VideoStatus.watching)
            .asFavorite()
            .build();

        when(mockVideoRepository.saveVideoMetadata(any))
            .thenAnswer((_) async {});

        // act
        await usecase.call(complexVideo);

        // assert
        final captured =
            verify(mockVideoRepository.saveVideoMetadata(captureAny))
                .captured
                .single as VideoFile;

        expect(captured.path, '/complex/video.mp4');
        expect(captured.name, 'Complex Video');
        expect(captured.thumbnailPath, '/complex/thumbnail.jpg');
        expect(captured.duration, const Duration(hours: 2, minutes: 30));
        expect(captured.fileSize, 5000000000);
        expect(captured.dateAdded, DateTime(2023, 6, 15));
        expect(captured.lastPlayedPosition, const Duration(minutes: 45));
        expect(captured.lastPlayedAt, DateTime(2023, 6, 20));
        expect(captured.lastPlayedAt, DateTime(2023, 6, 20));
        expect(captured.status, VideoStatus.watching);
        expect(captured.isFavorite, true);
      });

      test('should handle video with null optional fields', () async {
        // arrange
        final minimalVideo = VideoFile(
          path: TestConstants.testVideoPath,
          name: TestConstants.testVideoName,
        );
        when(mockVideoRepository.saveVideoMetadata(any))
            .thenAnswer((_) async {});

        // act
        await usecase.call(minimalVideo);

        // assert
        final captured =
            verify(mockVideoRepository.saveVideoMetadata(captureAny))
                .captured
                .single as VideoFile;

        expect(captured.path, TestConstants.testVideoPath);
        expect(captured.name, TestConstants.testVideoName);
        expect(captured.thumbnailPath, null);
        expect(captured.duration, null);
        expect(captured.fileSize, null);
        expect(captured.dateAdded, null);
        expect(captured.lastPlayedPosition, null);
        expect(captured.lastPlayedAt, null);
        expect(captured.status, VideoStatus.new_);
        expect(captured.isFavorite, false);
      });
    });

    group('Performance Tests', () {
      test('should handle multiple concurrent saves', () async {
        // arrange
        final videos = TestDataCollections.createMixedVideoList();
        when(mockVideoRepository.saveVideoMetadata(any))
            .thenAnswer((_) async {});

        // act
        final futures = videos.map((video) => usecase.call(video));
        await Future.wait(futures);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(any))
            .called(videos.length);
      });

      test('should handle large video metadata', () async {
        // arrange
        final largeVideo = VideoFileBuilder()
            .withPath(
                '/very/long/path/to/video/file/with/many/subdirectories/video.mp4')
            .withName(
                'Very Long Video Name That Exceeds Normal Length Expectations')
            .withFileSize(10000000000) // 10GB
            .withDuration(const Duration(hours: 10))
            .build();

        when(mockVideoRepository.saveVideoMetadata(any))
            .thenAnswer((_) async {});

        // act
        await usecase.call(largeVideo);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(largeVideo)).called(1);
      });
    });

    group('Business Logic Tests', () {
      test('should save video status progression correctly', () async {
        // arrange
        when(mockVideoRepository.saveVideoMetadata(any))
            .thenAnswer((_) async {});

        // act - simulate video status progression
        final newVideo = testVideoFile.copyWith(status: VideoStatus.new_);
        await usecase.call(newVideo);

        final partiallyWatchedVideo = newVideo.copyWith(
          status: VideoStatus.watching,
          lastPlayedPosition: const Duration(minutes: 5),
          lastPlayedAt: DateTime.now(),
        );
        await usecase.call(partiallyWatchedVideo);

        final watchedVideo = partiallyWatchedVideo.copyWith(
          status: VideoStatus.watched,
          lastPlayedPosition: testVideoFile.duration,
        );
        await usecase.call(watchedVideo);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(any)).called(3);
      });

      test('should save favorite toggle correctly', () async {
        // arrange
        when(mockVideoRepository.saveVideoMetadata(any))
            .thenAnswer((_) async {});

        // act - simulate favorite toggle
        final nonFavoriteVideo = testVideoFile.copyWith(isFavorite: false);
        await usecase.call(nonFavoriteVideo);

        final favoriteVideo = nonFavoriteVideo.copyWith(isFavorite: true);
        await usecase.call(favoriteVideo);

        final unfavoritedVideo = favoriteVideo.copyWith(isFavorite: false);
        await usecase.call(unfavoritedVideo);

        // assert
        verify(mockVideoRepository.saveVideoMetadata(any)).called(3);
      });
    });
  });
}
