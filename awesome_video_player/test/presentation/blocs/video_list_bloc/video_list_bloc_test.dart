import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/usecases/get_videos.dart';
import 'package:lumeo/domain/repositories/video_repository.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';

import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart'; // For PermissionDeniedException
import '../../../helpers/mock_factories.dart';

// Manual mock for GetVideos UseCase
class MockGetVideos extends Mock implements GetVideos {
  @override
  Future<List<VideoFile>> call() => super.noSuchMethod(
        Invocation.method(#call, []),
        returnValue: Future.value(<VideoFile>[]),
      );

  @override
  VideoRepository get repository => super.noSuchMethod(
        Invocation.getter(#repository),
        returnValue: MockVideoRepository(),
      );
}

void main() {
  // VideoListBloc instance will be created in build() method of blocTest

  final tVideoFiles = [
    VideoFile(path: '/video1.mp4', name: 'video1.mp4'),
    VideoFile(path: '/video2.mp4', name: 'video2.mp4'),
  ];
  const tPermissionDeniedMessage = "Video permission denied by user.";
  final tPermissionException =
      PermissionDeniedException(tPermissionDeniedMessage);
  final tGenericException =
      Exception("Failed to fetch videos due to a generic error.");

  test('initial state should be VideoListInitial', () {
    // VideoListBloc is created fresh for each blocTest, so this tests the constructor state.
    final mockGetVideos = MockGetVideos();
    expect(VideoListBloc(getVideos: mockGetVideos).state,
        const VideoListInitial());
  });

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListLoaded] when LoadVideos is added and GetVideos succeeds',
    build: () {
      final mockGetVideos = MockGetVideos();
      when(mockGetVideos.call()).thenAnswer((_) => Future.value(tVideoFiles));
      return VideoListBloc(getVideos: mockGetVideos);
    },
    expect: () => [
      const VideoListLoading(),
      isA<VideoListLoaded>()
          .having((state) => state.videos, 'videos', tVideoFiles),
    ],
  );

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListLoaded (empty)] when LoadVideos is added and GetVideos returns empty list',
    build: () {
      final mockGetVideos = MockGetVideos();
      when(mockGetVideos.call()).thenAnswer((_) => Future.value([]));
      return VideoListBloc(getVideos: mockGetVideos);
    },
    expect: () => [
      const VideoListLoading(),
      const VideoListEmpty(),
    ],
  );

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListPermissionDenied] when GetVideos throws PermissionDeniedException',
    build: () {
      final mockGetVideos = MockGetVideos();
      // This relies on GetVideos use case propagating the PermissionDeniedException
      // or VideoRepositoryImpl throwing it and GetVideos propagating it.
      // The VideoListBloc specifically catches PermissionDeniedException.
      when(mockGetVideos.call()).thenThrow(tPermissionException);
      return VideoListBloc(getVideos: mockGetVideos);
    },
    expect: () => [
      const VideoListLoading(),
      const VideoListError(
          "Permission denied. Please grant photo library access in settings."),
    ],
  );

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListError] when GetVideos throws a generic Exception',
    build: () {
      final mockGetVideos = MockGetVideos();
      when(mockGetVideos.call()).thenThrow(tGenericException);
      return VideoListBloc(getVideos: mockGetVideos);
    },
    expect: () => [
      const VideoListLoading(),
      VideoListError("Error: ${tGenericException.toString()}"),
    ],
  );
}
