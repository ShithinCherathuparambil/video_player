import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_video_player/domain/usecases/get_videos.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart'; // For Impl and PermissionDeniedException
import 'package:awesome_video_player/data/repositories/video_repository_impl.dart';
import './video_list_event.dart';
import './video_list_state.dart';

class VideoListBloc extends Bloc<VideoListEvent, VideoListState> {
  final GetVideos getVideosUseCase;

  VideoListBloc({required this.getVideosUseCase}) : super(VideoListInitial()) {
    on<LoadVideos>(_onLoadVideos);
    // Optionally, dispatch LoadVideos immediately if the list should load when BLoC is created
    // add(LoadVideos());
  }

  Future<void> _onLoadVideos(LoadVideos event, Emitter<VideoListState> emit) async {
    emit(VideoListLoading());
    try {
      final videos = await getVideosUseCase.call();
      if (videos.isEmpty) {
        // Check if this empty list is due to permissions or just no files.
        // The VideoRepositoryImpl currently returns empty list for PermissionDeniedException.
        // We might need a more specific way to distinguish this if VideoRepositoryImpl changes.
        // For now, if it's empty, it might be permission or just no files.
        // The VideoLocalDataSource throws PermissionDeniedException which VideoRepositoryImpl catches.
        // Let's assume VideoRepositoryImpl might rethrow a domain-specific permission error
        // or return a result object indicating permission status.
        // For this iteration, we rely on the current VideoRepositoryImpl behavior
        // which catches PermissionDeniedException and returns an empty list.
        // This means we can't easily distinguish "no files" from "permission denied" here
        // without modifying the repository layer.

        // A simple check could be to try to get permissions again or rely on a flag.
        // However, the current GetVideos use case doesn't expose permission status directly.

        // For this stage, let's assume if videos list is empty, it might be due to various reasons
        // including permissions, or simply no videos. The UI will show "no videos found" or
        // the message from VideoListError if an exception was thrown and caught below.
        // A more refined approach would have GetVideos return a result type (Either<Failure, List<VideoFile>>).
      }
      emit(VideoListLoaded(videos));
    } on PermissionDeniedException catch (e) { // Assuming GetVideos or its underlying layers might throw this
      emit(VideoListPermissionDenied(e.message));
    } catch (e) { // Catch other general errors
      emit(VideoListError("Failed to load videos: ${e.toString()}"));
    }
  }

  // Static create method for simplified DI as per subtask guideline
  static VideoListBloc create() {
    // VideoLocalDataSourceImpl doesn't need SharedPreferences, so it's simpler
    final videoLocalDataSource = VideoLocalDataSourceImpl();
    final videoRepository = VideoRepositoryImpl(localDataSource: videoLocalDataSource);
    final getVideosUseCase = GetVideos(videoRepository);

    return VideoListBloc(getVideosUseCase: getVideosUseCase);
  }
}
