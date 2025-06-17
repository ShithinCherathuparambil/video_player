import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/usecases/get_videos.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart'; // For PermissionDeniedException

// Manual mock for GetVideos UseCase
class MockGetVideos extends Mock implements GetVideos {}

void main() {
  late MockGetVideos mockGetVideos;
  // VideoListBloc instance will be created in build() method of blocTest

  setUp(() {
    mockGetVideos = MockGetVideos();
    // Note: VideoListBloc does not auto-load videos in constructor in current impl.
    // Events are dispatched by UI.
  });

  final tVideoFiles = [
    VideoFile(path: '/video1.mp4', name: 'video1.mp4'),
    VideoFile(path: '/video2.mp4', name: 'video2.mp4'),
  ];
  const tPermissionDeniedMessage = "Video permission denied by user.";
  final tPermissionException = PermissionDeniedException(tPermissionDeniedMessage);
  final tGenericException = Exception("Failed to fetch videos due to a generic error.");

  test('initial state should be VideoListInitial', () {
    // VideoListBloc is created fresh for each blocTest, so this tests the constructor state.
    expect(VideoListBloc(getVideosUseCase: mockGetVideos).state, VideoListInitial());
  });

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListLoaded] when LoadVideos is added and GetVideos succeeds',
    build: () {
      when(mockGetVideos.call()).thenAnswer((_) async => tVideoFiles);
      return VideoListBloc(getVideosUseCase: mockGetVideos);
    },
    act: (bloc) => bloc.add(LoadVideos()),
    expect: () => [
      VideoListLoading(),
      VideoListLoaded(tVideoFiles),
    ],
    verify: (_) {
      verify(mockGetVideos.call()).called(1);
    },
  );

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListLoaded (empty)] when LoadVideos is added and GetVideos returns empty list',
    build: () {
      when(mockGetVideos.call()).thenAnswer((_) async => []);
      return VideoListBloc(getVideosUseCase: mockGetVideos);
    },
    act: (bloc) => bloc.add(LoadVideos()),
    expect: () => [
      VideoListLoading(),
      const VideoListLoaded([]),
    ],
  );

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListPermissionDenied] when GetVideos throws PermissionDeniedException',
    build: () {
      // This relies on GetVideos use case propagating the PermissionDeniedException
      // or VideoRepositoryImpl throwing it and GetVideos propagating it.
      // The VideoListBloc specifically catches PermissionDeniedException.
      when(mockGetVideos.call()).thenThrow(tPermissionException);
      return VideoListBloc(getVideosUseCase: mockGetVideos);
    },
    act: (bloc) => bloc.add(LoadVideos()),
    expect: () => [
      VideoListLoading(),
      VideoListPermissionDenied(tPermissionException.message),
    ],
  );

  blocTest<VideoListBloc, VideoListState>(
    'emits [VideoListLoading, VideoListError] when GetVideos throws a generic Exception',
    build: () {
      when(mockGetVideos.call()).thenThrow(tGenericException);
      return VideoListBloc(getVideosUseCase: mockGetVideos);
    },
    act: (bloc) => bloc.add(LoadVideos()),
    expect: () => [
      VideoListLoading(),
      VideoListError("Failed to load videos: ${tGenericException.toString()}"),
    ],
  );
}
