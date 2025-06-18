import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For ThemeMode

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTheme extends ThemeEvent {}

class ChangeTheme extends ThemeEvent {
  final ThemeMode themeMode;

  const ChangeTheme(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ToggleGridView extends ThemeEvent {
  final bool isGridView;

  const ToggleGridView(this.isGridView);

  @override
  List<Object?> get props => [isGridView];
}

class ToggleSubtitles extends ThemeEvent {
  final bool subtitlesEnabled;

  const ToggleSubtitles(this.subtitlesEnabled);

  @override
  List<Object?> get props => [subtitlesEnabled];
}

class SetVideoDecoder extends ThemeEvent {
  final String videoDecoder;

  const SetVideoDecoder(this.videoDecoder);

  @override
  List<Object?> get props => [videoDecoder];
}

class ToggleHardwareAcceleration extends ThemeEvent {
  final bool hardwareAcceleration;

  const ToggleHardwareAcceleration(this.hardwareAcceleration);

  @override
  List<Object?> get props => [hardwareAcceleration];
}
