import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/usecases/get_videos.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';
import '../../helpers/test_constants.dart';

void main() {
  late GetVideos usecase;
  late MockVideoRepository mockVideoRepository;
  late List<VideoFile> testVideoFiles;

  setUp(() {
    mockVideoRepository = MockFactories.createMockVideoRepository();
    usecase = GetVideos(mockVideoRepository);
    testVideoFiles = TestDataCollections.createMixedVideoList();
  });

  group('GetVideos Use Case Tests', () {
    group('Successful Execution Tests', () {
      test('should get list of videos from the repository', () async {
        // arrange
        when(mockVideoRepository.getVideos())
            .thenAnswer((_) async => testVideoFiles);

        // act
        final result = await usecase.call();

        // assert
        expect(result, testVideoFiles);
        expect(result.length, testVideoFiles.length);
        verify(mockVideoRepository.getVideos()).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should return empty list when repository returns empty list',
          () async {
        // arrange
        when(mockVideoRepository.getVideos()).thenAnswer((_) async => []);

        // act
        final result = await usecase.call();

        // assert
        expect(result, isEmpty);
        verify(mockVideoRepository.getVideos()).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should return large list of videos', () async {
        // arrange
        final largeVideoList =
            TestDataCollections.createLargeVideoList(count: 100);
        when(mockVideoRepository.getVideos())
            .thenAnswer((_) async => largeVideoList);

        // act
        final result = await usecase.call();

        // assert
        expect(result, largeVideoList);
        expect(result.length, 100);
        verify(mockVideoRepository.getVideos()).called(1);
      });
    });

    group('Error Handling Tests', () {
      test('should propagate repository exceptions', () async {
        // arrange
        final exception = Exception('Repository error');
        when(mockVideoRepository.getVideos()).thenThrow(exception);

        // act & assert
        expect(() => usecase.call(), throwsA(exception));
        verify(mockVideoRepository.getVideos()).called(1);
      });

      test('should propagate permission denied exceptions', () async {
        // arrange
        final permissionException = Exception('Permission denied');
        when(mockVideoRepository.getVideos()).thenThrow(permissionException);

        // act & assert
        expect(() => usecase.call(), throwsA(permissionException));
        verify(mockVideoRepository.getVideos()).called(1);
      });

      test('should propagate network exceptions', () async {
        // arrange
        final networkException = Exception('Network error');
        when(mockVideoRepository.getVideos()).thenThrow(networkException);

        // act & assert
        expect(() => usecase.call(), throwsA(networkException));
        verify(mockVideoRepository.getVideos()).called(1);
      });
    });

    test('should handle timeout exceptions', () async {
      // arrange
      final timeoutException = Exception('Request timeout');
      when(mockVideoRepository.getVideos()).thenThrow(timeoutException);

      // act & assert
      expect(() => usecase.call(), throwsA(timeoutException));
      verify(mockVideoRepository.getVideos()).called(1);
    });
  });

  group('Performance Tests', () {
    test('should handle multiple concurrent calls', () async {
      // arrange
      when(mockVideoRepository.getVideos())
          .thenAnswer((_) async => testVideoFiles);

      // act
      final futures = List.generate(5, (_) => usecase.call());
      final results = await Future.wait(futures);

      // assert
      for (final result in results) {
        expect(result, testVideoFiles);
      }
      verify(mockVideoRepository.getVideos()).called(5);
    });
  });

  group('Integration Tests', () {
    test('should maintain video file properties', () async {
      // arrange
      final videoWithMetadata = VideoFileBuilder()
          .withPath(TestConstants.testVideoPath)
          .withName(TestConstants.testVideoName)
          .withDuration(TestConstants.mediumDuration)
          .withFileSize(TestConstants.mediumFileSize)
          .asFavorite()
          .asPartiallyWatched()
          .build();

      when(mockVideoRepository.getVideos())
          .thenAnswer((_) async => [videoWithMetadata]);

      // act
      final result = await usecase.call();

      // assert
      expect(result.length, 1);
      final returnedVideo = result.first;
      expect(returnedVideo.path, TestConstants.testVideoPath);
      expect(returnedVideo.name, TestConstants.testVideoName);
      expect(returnedVideo.duration, TestConstants.mediumDuration);
      expect(returnedVideo.fileSize, TestConstants.mediumFileSize);
      expect(returnedVideo.isFavorite, true);
      expect(returnedVideo.status, VideoStatus.watching);
    });
  });
}
