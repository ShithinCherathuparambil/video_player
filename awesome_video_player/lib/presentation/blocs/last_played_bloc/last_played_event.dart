import 'package:equatable/equatable.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:flutter/material.dart';

abstract class LastPlayedEvent extends Equatable {
  const LastPlayedEvent();

  @override
  List<Object?> get props => [];
}

class LoadLastPlayedVideo extends LastPlayedEvent {}

class SetLastPlayedVideo extends LastPlayedEvent {
  final VideoFile video;

  const SetLastPlayedVideo(this.video);

  @override
  List<Object?> get props => [video];
}

class ClearLastPlayedVideo extends LastPlayedEvent {}

class ShowLastPlayedCard extends LastPlayedEvent {}

class HideLastPlayedCard extends LastPlayedEvent {}

class UpdateCardPosition extends LastPlayedEvent {
  final Offset position;

  const UpdateCardPosition(this.position);

  @override
  List<Object?> get props => [position];
}

class SavePlaybackPosition extends LastPlayedEvent {
  final Duration position;

  const SavePlaybackPosition(this.position);

  @override
  List<Object?> get props => [position];
}
