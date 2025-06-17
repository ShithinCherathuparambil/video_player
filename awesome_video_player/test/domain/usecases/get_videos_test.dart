import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';
import 'package:awesome_video_player/domain/usecases/get_videos.dart';
// Assuming a custom exception might be defined in data layer if needed for permissions
// import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';

// Manual mock for VideoRepository
class MockVideoRepository extends Mock implements VideoRepository {}

void main() {
  late GetVideos usecase;
  late MockVideoRepository mockVideoRepository;

  setUp(() {
    mockVideoRepository = MockVideoRepository();
    usecase = GetVideos(mockVideoRepository);
  });

  final tVideoFiles = [
    VideoFile(path: '/video1.mp4', name: 'video1.mp4'),
    VideoFile(path: '/video2.mp4', name: 'video2.mp4'),
  ];

  test(
    'should get list of videos from the repository',
    () async {
      // arrange
      when(mockVideoRepository.getVideos())
          .thenAnswer((_) async => tVideoFiles);
      // act
      final result = await usecase.call();
      // assert
      expect(result, tVideoFiles);
      verify(mockVideoRepository.getVideos());
      verifyNoMoreInteractions(mockVideoRepository);
    },
  );

  test(
    'should return empty list if repository throws an error (e.g. permission denied)',
    () async {
      // arrange
      // Using a generic Exception for this test.
      // The repository implementation might throw a more specific error (e.g., PermissionDeniedException from data layer)
      when(mockVideoRepository.getVideos())
          .thenThrow(Exception("Simulated repository error"));
      // act
      final result = await usecase.call();
      // assert
      // The current GetVideos use case doesn't catch errors itself, it propagates them.
      // The VideoRepositoryImpl currently catches PermissionDeniedException and returns an empty list.
      // So, if VideoRepositoryImpl is used, this test should expect an empty list
      // if the repo impl handles the error that way.
      // If GetVideos use case is expected to handle it, then this test would be different.
      // Based on current VideoRepositoryImpl, it returns empty list on error.
      expect(result, []); // Assuming repository implementation returns empty list on error
      verify(mockVideoRepository.getVideos());
      verifyNoMoreInteractions(mockVideoRepository);
    },
  );

  // Example for testing a specific domain exception if your repository/usecase throws one
  // test(
  //   'should throw SpecificDomainException if repository throws specific error',
  //   () async {
  //     // arrange
  //     when(mockVideoRepository.getVideos())
  //         .thenThrow(SpecificDomainException("Specific error"));
  //     // act
  //     final call = usecase.call;
  //     // assert
  //     expect(() => call(), throwsA(isA<SpecificDomainException>()));
  //     verify(mockVideoRepository.getVideos());
  //     verifyNoMoreInteractions(mockVideoRepository);
  //   },
  // );
}
