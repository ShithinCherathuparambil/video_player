import 'package:equatable/equatable.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:flutter/material.dart';

abstract class LastPlayedState extends Equatable {
  const LastPlayedState();

  @override
  List<Object?> get props => [];
}

class LastPlayedInitial extends LastPlayedState {}

class LastPlayedLoading extends LastPlayedState {}

class LastPlayedLoaded extends LastPlayedState {
  final VideoFile? lastPlayedVideo;
  final bool showCard;
  final Offset cardPosition;
  final Duration? playbackPosition;

  const LastPlayedLoaded({
    this.lastPlayedVideo,
    this.showCard = false,
    this.cardPosition = const Offset(20, 100),
    this.playbackPosition,
  });

  @override
  List<Object?> get props =>
      [lastPlayedVideo, showCard, cardPosition, playbackPosition];

  LastPlayedLoaded copyWith({
    VideoFile? lastPlayedVideo,
    bool? showCard,
    Offset? cardPosition,
    Duration? playbackPosition,
  }) {
    return LastPlayedLoaded(
      lastPlayedVideo: lastPlayedVideo ?? this.lastPlayedVideo,
      showCard: showCard ?? this.showCard,
      cardPosition: cardPosition ?? this.cardPosition,
      playbackPosition: playbackPosition ?? this.playbackPosition,
    );
  }
}

class LastPlayedError extends LastPlayedState {
  final String message;

  const LastPlayedError(this.message);

  @override
  List<Object?> get props => [message];
}
