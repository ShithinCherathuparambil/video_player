import 'dart:io'; // For Platform.pathSeparator, not strictly needed for test logic but good for context
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';
import 'package:awesome_video_player/data/repositories/video_repository_impl.dart';

// Manual mock for VideoLocalDataSource
class MockVideoLocalDataSource extends Mock implements VideoLocalDataSource {}

void main() {
  late VideoRepositoryImpl repository;
  late MockVideoLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockVideoLocalDataSource();
    repository = VideoRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getVideos', () {
    final tVideoPaths = ['/path/to/video1.mp4', '/another/path/video2.mov'];
    final tExpectedVideoFiles = [
      VideoFile(path: '/path/to/video1.mp4', name: 'video1.mp4'),
      VideoFile(path: '/another/path/video2.mov', name: 'video2.mov'),
    ];

    test(
      'should get video paths from local data source and map them to VideoFile entities',
      () async {
        // arrange
        when(mockLocalDataSource.getVideoPaths())
            .thenAnswer((_) async => tVideoPaths);
        // act
        final result = await repository.getVideos();
        // assert
        expect(result, tExpectedVideoFiles);
        verify(mockLocalDataSource.getVideoPaths());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return an empty list when data source returns an empty list of paths',
      () async {
        // arrange
        when(mockLocalDataSource.getVideoPaths()).thenAnswer((_) async => []);
        // act
        final result = await repository.getVideos();
        // assert
        expect(result, []);
        verify(mockLocalDataSource.getVideoPaths());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return an empty list when data source throws PermissionDeniedException',
      () async {
        // arrange
        when(mockLocalDataSource.getVideoPaths())
            .thenThrow(PermissionDeniedException('Permission denied'));
        // act
        final result = await repository.getVideos();
        // assert
        // The current VideoRepositoryImpl catches PermissionDeniedException and returns an empty list.
        expect(result, []);
        verify(mockLocalDataSource.getVideoPaths());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return an empty list when data source throws a generic Exception',
      () async {
        // arrange
        when(mockLocalDataSource.getVideoPaths())
            .thenThrow(Exception('Some other error'));
        // act
        final result = await repository.getVideos();
        // assert
        // The current VideoRepositoryImpl catches generic exceptions and returns an empty list.
        expect(result, []);
        verify(mockLocalDataSource.getVideoPaths());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });
}
