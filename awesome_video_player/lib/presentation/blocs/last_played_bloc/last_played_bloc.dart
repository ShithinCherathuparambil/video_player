import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import './last_played_event.dart';
import './last_played_state.dart';

class LastPlayedBloc extends Bloc<LastPlayedEvent, LastPlayedState> {
  static const String _lastPlayedKey = 'last_played_video';
  static const String _showCardKey = 'show_last_played_card';
  static const String _cardPositionKey = 'card_position';
  static const String _playbackPositionKey = 'playback_position';

  LastPlayedBloc() : super(LastPlayedInitial()) {
    on<LoadLastPlayedVideo>(_onLoadLastPlayedVideo);
    on<SetLastPlayedVideo>(_onSetLastPlayedVideo);
    on<ClearLastPlayedVideo>(_onClearLastPlayedVideo);
    on<ShowLastPlayedCard>(_onShowLastPlayedCard);
    on<HideLastPlayedCard>(_onHideLastPlayedCard);
    on<UpdateCardPosition>(_onUpdateCardPosition);
    on<SavePlaybackPosition>(_onSavePlaybackPosition);

    add(LoadLastPlayedVideo());
  }

  Future<void> _onLoadLastPlayedVideo(
      LoadLastPlayedVideo event, Emitter<LastPlayedState> emit) async {
    emit(LastPlayedLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoJson = prefs.getString(_lastPlayedKey);
      final showCard = prefs.getBool(_showCardKey) ?? false;

      // Load card position
      final positionX = prefs.getDouble('${_cardPositionKey}_x') ?? 20.0;
      final positionY = prefs.getDouble('${_cardPositionKey}_y') ?? 100.0;
      final cardPosition = Offset(positionX, positionY);

      // Load playback position
      final playbackPositionMs = prefs.getInt(_playbackPositionKey);
      final playbackPosition = playbackPositionMs != null
          ? Duration(milliseconds: playbackPositionMs)
          : null;

      VideoFile? lastPlayedVideo;
      if (videoJson != null) {
        final videoMap = json.decode(videoJson) as Map<String, dynamic>;
        lastPlayedVideo = VideoFile.fromJson(videoMap);
      }

      emit(LastPlayedLoaded(
        lastPlayedVideo: lastPlayedVideo,
        showCard: showCard,
        cardPosition: cardPosition,
        playbackPosition: playbackPosition,
      ));
    } catch (e) {
      emit(
          LastPlayedError('Failed to load last played video: ${e.toString()}'));
    }
  }

  Future<void> _onSetLastPlayedVideo(
      SetLastPlayedVideo event, Emitter<LastPlayedState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoJson = json.encode(event.video.toJson());
      await prefs.setString(_lastPlayedKey, videoJson);
      await prefs.setBool(_showCardKey, true);

      if (state is LastPlayedLoaded) {
        final currentState = state as LastPlayedLoaded;
        emit(currentState.copyWith(
          lastPlayedVideo: event.video,
          showCard: true,
        ));
      } else {
        emit(LastPlayedLoaded(
          lastPlayedVideo: event.video,
          showCard: true,
        ));
      }
    } catch (e) {
      emit(
          LastPlayedError('Failed to save last played video: ${e.toString()}'));
    }
  }

  Future<void> _onClearLastPlayedVideo(
      ClearLastPlayedVideo event, Emitter<LastPlayedState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastPlayedKey);
      await prefs.setBool(_showCardKey, false);
      await prefs.remove(_playbackPositionKey);

      emit(const LastPlayedLoaded(
        lastPlayedVideo: null,
        showCard: false,
      ));
    } catch (e) {
      emit(LastPlayedError(
          'Failed to clear last played video: ${e.toString()}'));
    }
  }

  Future<void> _onShowLastPlayedCard(
      ShowLastPlayedCard event, Emitter<LastPlayedState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showCardKey, true);

      if (state is LastPlayedLoaded) {
        final currentState = state as LastPlayedLoaded;
        emit(currentState.copyWith(showCard: true));
      }
    } catch (e) {
      emit(LastPlayedError('Failed to show last played card: ${e.toString()}'));
    }
  }

  Future<void> _onHideLastPlayedCard(
      HideLastPlayedCard event, Emitter<LastPlayedState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showCardKey, false);

      if (state is LastPlayedLoaded) {
        final currentState = state as LastPlayedLoaded;
        emit(currentState.copyWith(showCard: false));
      }
    } catch (e) {
      emit(LastPlayedError('Failed to hide last played card: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCardPosition(
      UpdateCardPosition event, Emitter<LastPlayedState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${_cardPositionKey}_x', event.position.dx);
      await prefs.setDouble('${_cardPositionKey}_y', event.position.dy);

      if (state is LastPlayedLoaded) {
        final currentState = state as LastPlayedLoaded;
        emit(currentState.copyWith(cardPosition: event.position));
      }
    } catch (e) {
      emit(LastPlayedError('Failed to update card position: ${e.toString()}'));
    }
  }

  Future<void> _onSavePlaybackPosition(
      SavePlaybackPosition event, Emitter<LastPlayedState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_playbackPositionKey, event.position.inMilliseconds);

      if (state is LastPlayedLoaded) {
        final currentState = state as LastPlayedLoaded;
        emit(currentState.copyWith(playbackPosition: event.position));
      }
    } catch (e) {
      emit(
          LastPlayedError('Failed to save playback position: ${e.toString()}'));
    }
  }

  static LastPlayedBloc create() {
    return LastPlayedBloc();
  }
}
