import 'dart:io'; // For Platform.pathSeparator, not strictly needed for test logic but good for context
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';
import 'package:awesome_video_player/data/repositories/video_repository_impl.dart';

// Import PermissionDeniedException for tests
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);
  @override
  String toString() => 'PermissionDeniedException: $message';
}

// Manual mock for VideoLocalDataSource
class MockVideoLocalDataSource extends Mock implements VideoLocalDataSource {
  @override
  Future<List<VideoFile>> getVideos() => super.noSuchMethod(
        Invocation.method(#getVideos, []),
        returnValue: Future.value(<VideoFile>[]),
      );

  @override
  Future<void> requestPermissions() => super.noSuchMethod(
        Invocation.method(#requestPermissions, []),
        returnValue: Future<void>.value(),
      );
}

void main() {
  late VideoRepositoryImpl repository;
  late MockVideoLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockVideoLocalDataSource();
    repository = VideoRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('getVideos', () {
    final tExpectedVideoFiles = [
      VideoFile(path: '/path/to/video1.mp4', name: 'video1.mp4'),
      VideoFile(path: '/another/path/video2.mov', name: 'video2.mov'),
    ];

    test(
      'should get videos from local data source',
      () async {
        // arrange
        when(mockLocalDataSource.requestPermissions()).thenAnswer((_) async {});
        when(mockLocalDataSource.getVideos())
            .thenAnswer((_) async => tExpectedVideoFiles);
        // act
        final result = await repository.getVideos();
        // assert
        expect(result, tExpectedVideoFiles);
        verify(mockLocalDataSource.requestPermissions());
        verify(mockLocalDataSource.getVideos());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return an empty list when data source returns an empty list',
      () async {
        // arrange
        when(mockLocalDataSource.requestPermissions()).thenAnswer((_) async {});
        when(mockLocalDataSource.getVideos()).thenAnswer((_) async => []);
        // act
        final result = await repository.getVideos();
        // assert
        expect(result, []);
        verify(mockLocalDataSource.requestPermissions());
        verify(mockLocalDataSource.getVideos());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return an empty list when requestPermissions throws PermissionDeniedException',
      () async {
        // arrange
        when(mockLocalDataSource.requestPermissions())
            .thenThrow(PermissionDeniedException('Permission denied'));
        // act
        final result = await repository.getVideos();
        // assert
        // The current VideoRepositoryImpl catches PermissionDeniedException and returns an empty list.
        expect(result, []);
        verify(mockLocalDataSource.requestPermissions());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );

    test(
      'should return an empty list when requestPermissions throws a generic Exception',
      () async {
        // arrange
        when(mockLocalDataSource.requestPermissions())
            .thenThrow(Exception('Some other error'));
        // act
        final result = await repository.getVideos();
        // assert
        // The current VideoRepositoryImpl catches generic exceptions and returns an empty list.
        expect(result, []);
        verify(mockLocalDataSource.requestPermissions());
        verifyNoMoreInteractions(mockLocalDataSource);
      },
    );
  });
}
