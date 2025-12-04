import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/playlist_bloc/playlist_event.dart';
import 'package:lumeo/presentation/blocs/playlist_bloc/playlist_state.dart';

class PlaylistBloc extends Bloc<PlaylistEvent, PlaylistState> {
  PlaylistBloc() : super(const PlaylistInitial()) {
    on<LoadPlaylist>(_onLoadPlaylist);
    on<AddToPlaylist>(_onAddToPlaylist);
    on<RemoveFromPlaylist>(_onRemoveFromPlaylist);
    on<ReorderPlaylist>(_onReorderPlaylist);
    on<SetCurrentVideo>(_onSetCurrentVideo);
    on<PlayNext>(_onPlayNext);
    on<PlayPrevious>(_onPlayPrevious);
    on<ShufflePlaylist>(_onShufflePlaylist);
    on<ClearPlaylist>(_onClearPlaylist);
  }

  void _onLoadPlaylist(LoadPlaylist event, Emitter<PlaylistState> emit) {
    emit(PlaylistLoaded(videos: event.videos));
  }

  void _onAddToPlaylist(AddToPlaylist event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      final updatedVideos = List<VideoFile>.from(currentState.videos)..add(event.video);
      emit(currentState.copyWith(videos: updatedVideos));
    } else {
      emit(PlaylistLoaded(videos: [event.video]));
    }
  }

  void _onRemoveFromPlaylist(RemoveFromPlaylist event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      final updatedVideos = currentState.videos.where((v) => v.path != event.videoPath).toList();
      int newIndex = currentState.currentIndex;
      
      // Adjust current index if needed
      if (currentState.currentIndex >= updatedVideos.length) {
        newIndex = updatedVideos.length > 0 ? updatedVideos.length - 1 : 0;
      } else if (currentState.currentIndex > 0 && 
                 currentState.videos[currentState.currentIndex].path == event.videoPath) {
        newIndex = currentState.currentIndex - 1;
      }
      
      emit(currentState.copyWith(videos: updatedVideos, currentIndex: newIndex));
    }
  }

  void _onReorderPlaylist(ReorderPlaylist event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      final updatedVideos = List<VideoFile>.from(currentState.videos);
      final item = updatedVideos.removeAt(event.oldIndex);
      updatedVideos.insert(event.newIndex, item);
      
      int newIndex = currentState.currentIndex;
      if (currentState.currentIndex == event.oldIndex) {
        newIndex = event.newIndex;
      } else if (currentState.currentIndex > event.oldIndex && currentState.currentIndex <= event.newIndex) {
        newIndex = currentState.currentIndex - 1;
      } else if (currentState.currentIndex < event.oldIndex && currentState.currentIndex >= event.newIndex) {
        newIndex = currentState.currentIndex + 1;
      }
      
      emit(currentState.copyWith(videos: updatedVideos, currentIndex: newIndex));
    }
  }

  void _onSetCurrentVideo(SetCurrentVideo event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      if (event.index >= 0 && event.index < currentState.videos.length) {
        emit(currentState.copyWith(currentIndex: event.index));
      }
    }
  }

  void _onPlayNext(PlayNext event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      if (currentState.videos.isNotEmpty) {
        final nextIndex = (currentState.currentIndex + 1) % currentState.videos.length;
        emit(currentState.copyWith(currentIndex: nextIndex));
      }
    }
  }

  void _onPlayPrevious(PlayPrevious event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      if (currentState.videos.isNotEmpty) {
        final prevIndex = (currentState.currentIndex - 1 + currentState.videos.length) % currentState.videos.length;
        emit(currentState.copyWith(currentIndex: prevIndex));
      }
    }
  }

  void _onShufflePlaylist(ShufflePlaylist event, Emitter<PlaylistState> emit) {
    if (state is PlaylistLoaded) {
      final currentState = state as PlaylistLoaded;
      final shuffledVideos = List<VideoFile>.from(currentState.videos);
      shuffledVideos.shuffle(Random());
      emit(PlaylistLoaded(videos: shuffledVideos, currentIndex: 0));
    }
  }

  void _onClearPlaylist(ClearPlaylist event, Emitter<PlaylistState> emit) {
    emit(const PlaylistInitial());
  }
}

