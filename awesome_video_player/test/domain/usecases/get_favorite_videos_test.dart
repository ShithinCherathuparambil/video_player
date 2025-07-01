import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';
import 'package:lumeo/domain/usecases/get_favorite_videos.dart';
import '../../helpers/mock_factories.dart';
import '../../helpers/test_data_builders.dart';
import '../../helpers/test_constants.dart';

void main() {
  group('GetFavoriteVideos Use Case Tests', () {
    late GetFavoriteVideos usecase;
    late MockVideoRepository mockVideoRepository;
    late List<VideoFile> testFavoriteVideos;

    setUp(() {
      mockVideoRepository = MockFactories.createMockVideoRepository();
      usecase = GetFavoriteVideos(mockVideoRepository);
      testFavoriteVideos = TestDataCollections.createFavoriteVideoList();
    });

    group('Successful Execution Tests', () {
      test('should get list of favorite videos from repository', () async {
        // arrange
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => testFavoriteVideos);

        // act
        final result = await usecase.call();

        // assert
        expect(result, testFavoriteVideos);
        expect(result.length, testFavoriteVideos.length);
        expect(result.every((video) => video.isFavorite), true);
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should return empty list when no favorites exist', () async {
        // arrange
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => []);

        // act
        final result = await usecase.call();

        // assert
        expect(result, isEmpty);
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });

      test('should return single favorite video', () async {
        // arrange
        final singleFavorite = [
          VideoFileBuilder()
              .withPath(TestConstants.testVideoPath)
              .withName(TestConstants.testVideoName)
              .asFavorite()
              .build()
        ];
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => singleFavorite);

        // act
        final result = await usecase.call();

        // assert
        expect(result, singleFavorite);
        expect(result.length, 1);
        expect(result.first.isFavorite, true);
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });

      test('should return multiple favorite videos', () async {
        // arrange
        final multipleFavorites = List.generate(
            5,
            (index) => VideoFileBuilder()
                .withPath('/favorite$index.mp4')
                .withName('Favorite $index')
                .asFavorite()
                .build());
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => multipleFavorites);

        // act
        final result = await usecase.call();

        // assert
        expect(result, multipleFavorites);
        expect(result.length, 5);
        expect(result.every((video) => video.isFavorite), true);
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });
    });

    group('Error Handling Tests', () {
      test('should propagate repository exceptions', () async {
        // arrange
        final exception = Exception('Failed to get favorites');
        when(mockVideoRepository.getFavoriteVideos()).thenThrow(exception);

        // act & assert
        expect(() => usecase.call(), throwsA(exception));
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });

      test('should propagate permission exceptions', () async {
        // arrange
        final permissionException = Exception('Permission denied');
        when(mockVideoRepository.getFavoriteVideos())
            .thenThrow(permissionException);

        // act & assert
        expect(() => usecase.call(), throwsA(permissionException));
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });

      test('should propagate storage exceptions', () async {
        // arrange
        final storageException = Exception('Storage error');
        when(mockVideoRepository.getFavoriteVideos())
            .thenThrow(storageException);

        // act & assert
        expect(() => usecase.call(), throwsA(storageException));
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });

      test('should propagate network exceptions', () async {
        // arrange
        final networkException = Exception('Network error');
        when(mockVideoRepository.getFavoriteVideos())
            .thenThrow(networkException);

        // act & assert
        expect(() => usecase.call(), throwsA(networkException));
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });
    });

    group('Data Integrity Tests', () {
      test('should preserve all video properties for favorites', () async {
        // arrange
        final favoriteWithMetadata = VideoFileBuilder()
            .withPath('/complex/favorite.mp4')
            .withName('Complex Favorite')
            .withThumbnailPath('/complex/thumbnail.jpg')
            .withDuration(const Duration(hours: 1, minutes: 30))
            .withFileSize(2000000000) // 2GB
            .withDateAdded(DateTime(2023, 5, 10))
            .withLastPlayedPosition(const Duration(minutes: 20))
            .withLastPlayedAt(DateTime(2023, 5, 15))
            .withStatus(VideoStatus.partiallyWatched)
            .asFavorite()
            .build();

        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => [favoriteWithMetadata]);

        // act
        final result = await usecase.call();

        // assert
        expect(result.length, 1);
        final returnedVideo = result.first;
        expect(returnedVideo.path, '/complex/favorite.mp4');
        expect(returnedVideo.name, 'Complex Favorite');
        expect(returnedVideo.thumbnailPath, '/complex/thumbnail.jpg');
        expect(returnedVideo.duration, const Duration(hours: 1, minutes: 30));
        expect(returnedVideo.fileSize, 2000000000);
        expect(returnedVideo.dateAdded, DateTime(2023, 5, 10));
        expect(returnedVideo.lastPlayedPosition, const Duration(minutes: 20));
        expect(returnedVideo.lastPlayedAt, DateTime(2023, 5, 15));
        expect(returnedVideo.status, VideoStatus.partiallyWatched);
        expect(returnedVideo.isFavorite, true);
      });

      test('should handle favorites with different statuses', () async {
        // arrange
        final favoritesWithDifferentStatuses = [
          VideoFileBuilder()
              .withPath('/new_favorite.mp4')
              .withStatus(VideoStatus.new_)
              .asFavorite()
              .build(),
          VideoFileBuilder()
              .withPath('/partial_favorite.mp4')
              .withStatus(VideoStatus.partiallyWatched)
              .asFavorite()
              .build(),
          VideoFileBuilder()
              .withPath('/watched_favorite.mp4')
              .withStatus(VideoStatus.watched)
              .asFavorite()
              .build(),
        ];

        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => favoritesWithDifferentStatuses);

        // act
        final result = await usecase.call();

        // assert
        expect(result.length, 3);
        expect(result.every((video) => video.isFavorite), true);
        expect(result[0].status, VideoStatus.new_);
        expect(result[1].status, VideoStatus.partiallyWatched);
        expect(result[2].status, VideoStatus.watched);
      });

      test('should handle favorites with null optional fields', () async {
        // arrange
        final minimalFavorite = VideoFile(
          path: TestConstants.testVideoPath,
          name: TestConstants.testVideoName,
          isFavorite: true,
        );

        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => [minimalFavorite]);

        // act
        final result = await usecase.call();

        // assert
        expect(result.length, 1);
        final returnedVideo = result.first;
        expect(returnedVideo.path, TestConstants.testVideoPath);
        expect(returnedVideo.name, TestConstants.testVideoName);
        expect(returnedVideo.isFavorite, true);
        expect(returnedVideo.thumbnailPath, null);
        expect(returnedVideo.duration, null);
        expect(returnedVideo.fileSize, null);
        expect(returnedVideo.dateAdded, null);
        expect(returnedVideo.lastPlayedPosition, null);
        expect(returnedVideo.lastPlayedAt, null);
        expect(returnedVideo.status, VideoStatus.new_);
      });
    });

    group('Performance Tests', () {
      test('should handle large list of favorite videos', () async {
        // arrange
        final largeFavoriteList = List.generate(
            100,
            (index) => VideoFileBuilder()
                .withPath('/favorite$index.mp4')
                .withName('Favorite $index')
                .asFavorite()
                .build());
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => largeFavoriteList);

        // act
        final result = await usecase.call();

        // assert
        expect(result, largeFavoriteList);
        expect(result.length, 100);
        expect(result.every((video) => video.isFavorite), true);
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
      });

      test('should handle multiple concurrent calls', () async {
        // arrange
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => testFavoriteVideos);

        // act
        final futures = List.generate(5, (_) => usecase.call());
        final results = await Future.wait(futures);

        // assert
        for (final result in results) {
          expect(result, testFavoriteVideos);
          expect(result.every((video) => video.isFavorite), true);
        }
        verify(mockVideoRepository.getFavoriteVideos()).called(5);
      });
    });

    group('Business Logic Tests', () {
      test('should only return videos marked as favorites', () async {
        // arrange
        final mixedVideos = [
          VideoFileBuilder().withPath('/favorite1.mp4').asFavorite().build(),
          VideoFileBuilder()
              .withPath('/not_favorite.mp4')
              .asNotFavorite()
              .build(),
          VideoFileBuilder().withPath('/favorite2.mp4').asFavorite().build(),
        ];

        // Repository should only return favorites
        final onlyFavorites = mixedVideos.where((v) => v.isFavorite).toList();
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => onlyFavorites);

        // act
        final result = await usecase.call();

        // assert
        expect(result.length, 2);
        expect(result.every((video) => video.isFavorite), true);
        expect(result.map((v) => v.path),
            containsAll(['/favorite1.mp4', '/favorite2.mp4']));
      });

      test('should maintain order returned by repository', () async {
        // arrange
        final orderedFavorites = [
          VideoFileBuilder().withPath('/z_favorite.mp4').asFavorite().build(),
          VideoFileBuilder().withPath('/a_favorite.mp4').asFavorite().build(),
          VideoFileBuilder().withPath('/m_favorite.mp4').asFavorite().build(),
        ];
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => orderedFavorites);

        // act
        final result = await usecase.call();

        // assert
        expect(result, orderedFavorites);
        expect(result[0].path, '/z_favorite.mp4');
        expect(result[1].path, '/a_favorite.mp4');
        expect(result[2].path, '/m_favorite.mp4');
      });
    });

    group('Integration Tests', () {
      test('should work correctly with repository implementation', () async {
        // arrange
        when(mockVideoRepository.getFavoriteVideos())
            .thenAnswer((_) async => testFavoriteVideos);

        // act
        final result = await usecase.call();

        // assert
        expect(result, testFavoriteVideos);
        verify(mockVideoRepository.getFavoriteVideos()).called(1);
        verifyNoMoreInteractions(mockVideoRepository);
      });
    });
  });
}
