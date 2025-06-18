import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart'; // For ThemeMode

abstract class ThemeState extends Equatable {
  const ThemeState();

  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeLoading
    extends ThemeState {} // Optional: if loading is async and needs UI feedback

class ThemeLoaded extends ThemeState {
  final ThemeMode themeMode;
  final bool isGridView;
  final bool subtitlesEnabled;
  final String videoDecoder;
  final bool hardwareAcceleration;

  const ThemeLoaded({
    required this.themeMode,
    this.isGridView = true, // Default to grid view
    this.subtitlesEnabled = false, // Default to subtitles disabled
    this.videoDecoder = 'auto', // Default to auto
    this.hardwareAcceleration = true, // Default to enabled
  });

  @override
  List<Object?> get props => [
        themeMode,
        isGridView,
        subtitlesEnabled,
        videoDecoder,
        hardwareAcceleration
      ];
}

class ThemeError extends ThemeState {
  final String message;

  const ThemeError(this.message);

  @override
  List<Object?> get props => [message];
}
