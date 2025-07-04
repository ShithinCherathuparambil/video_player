import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_event.dart';

/// Service to handle cross-BLoC communication for video deletion synchronization
class BlocCommunicationService {
  static VideoListBloc? _videoListBloc;
  static FavoritesBloc? _favoritesBloc;

  /// Register the VideoListBloc instance
  static void registerVideoListBloc(VideoListBloc bloc) {
    _videoListBloc = bloc;
  }

  /// Register the FavoritesBloc instance
  static void registerFavoritesBloc(FavoritesBloc bloc) {
    _favoritesBloc = bloc;
  }

  /// Instantly notify favorites bloc that a video was deleted from main list
  static void notifyFavoritesOfDeletion(String videoPath) {
    if (_favoritesBloc != null && !_favoritesBloc!.isClosed) {
      // Instantly remove the video from favorites list without full reload
      _favoritesBloc!.add(InstantRemoveFromFavorites(videoPath));
    }
  }

  /// Instantly notify video list bloc that a video was deleted from favorites
  static void notifyVideoListOfDeletion(String videoPath) {
    if (_videoListBloc != null && !_videoListBloc!.isClosed) {
      // Instantly remove the video from main list without full reload
      _videoListBloc!.add(InstantRemoveFromList(videoPath));
    }
  }

  /// Clean up references when BLoCs are disposed
  static void dispose() {
    _videoListBloc = null;
    _favoritesBloc = null;
  }
}
