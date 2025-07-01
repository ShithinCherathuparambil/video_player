import 'package:flutter_bloc/flutter_bloc.dart';
// SharedPreferences import is no longer directly needed here for DI
import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/usecases/get_theme_settings.dart';
import 'package:lumeo/domain/usecases/save_theme_settings.dart';
import 'package:lumeo/data/datasources/settings_local_data_source.dart';
import 'package:lumeo/data/repositories/settings_repository_impl.dart';
import './theme_event.dart';
import './theme_state.dart';
import 'package:flutter/material.dart'; // For ThemeMode

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final GetThemeSettings getThemeSettings;
  final SaveThemeSettings saveThemeSettings;

  ThemeBloc({
    required this.getThemeSettings,
    required this.saveThemeSettings,
  }) : super(ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ChangeTheme>(_onChangeTheme);
    on<ToggleGridView>(_onToggleGridView);
    on<ToggleSubtitles>(_onToggleSubtitles);
    on<SetVideoDecoder>(_onSetVideoDecoder);
    on<ToggleHardwareAcceleration>(_onToggleHardwareAcceleration);

    add(LoadTheme());
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    emit(ThemeLoading());
    try {
      final appSettings = await getThemeSettings.call();
      emit(ThemeLoaded(
        themeMode: appSettings.themeMode,
        isGridView: appSettings.isGridView ?? true, // Default to grid view
        subtitlesEnabled: appSettings.subtitlesEnabled,
        videoDecoder: appSettings.videoDecoder,
        hardwareAcceleration: appSettings.hardwareAcceleration,
      ));
    } catch (e) {
      emit(ThemeError("Failed to load theme: ${e.toString()}"));
      // Fallback to a default theme if loading fails
      emit(const ThemeLoaded(
        themeMode: ThemeMode.system,
        isGridView: true,
        subtitlesEnabled: false,
        videoDecoder: 'auto',
        hardwareAcceleration: true,
      )); // Default to system on error
    }
  }

  Future<void> _onChangeTheme(
      ChangeTheme event, Emitter<ThemeState> emit) async {
    try {
      final currentState = state;
      final isGridView =
          currentState is ThemeLoaded ? currentState.isGridView : true;
      final subtitlesEnabled =
          currentState is ThemeLoaded ? currentState.subtitlesEnabled : false;
      final videoDecoder =
          currentState is ThemeLoaded ? currentState.videoDecoder : 'auto';
      final hardwareAcceleration = currentState is ThemeLoaded
          ? currentState.hardwareAcceleration
          : true;

      final newAppSettings = AppSettings(
        themeMode: event.themeMode,
        isGridView: isGridView,
        subtitlesEnabled: subtitlesEnabled,
        videoDecoder: videoDecoder,
        hardwareAcceleration: hardwareAcceleration,
      );
      await saveThemeSettings.call(newAppSettings);
      emit(ThemeLoaded(
        themeMode: event.themeMode,
        isGridView: isGridView,
        subtitlesEnabled: subtitlesEnabled,
        videoDecoder: videoDecoder,
        hardwareAcceleration: hardwareAcceleration,
      ));
    } catch (e) {
      emit(ThemeError("Failed to save theme: ${e.toString()}"));
    }
  }

  Future<void> _onToggleGridView(
      ToggleGridView event, Emitter<ThemeState> emit) async {
    try {
      final currentState = state;
      if (currentState is ThemeLoaded) {
        final newAppSettings = AppSettings(
          themeMode: currentState.themeMode,
          isGridView: event.isGridView,
          subtitlesEnabled: currentState.subtitlesEnabled,
          videoDecoder: currentState.videoDecoder,
          hardwareAcceleration: currentState.hardwareAcceleration,
        );
        await saveThemeSettings.call(newAppSettings);
        emit(ThemeLoaded(
          themeMode: currentState.themeMode,
          isGridView: event.isGridView,
          subtitlesEnabled: currentState.subtitlesEnabled,
          videoDecoder: currentState.videoDecoder,
          hardwareAcceleration: currentState.hardwareAcceleration,
        ));
      }
    } catch (e) {
      emit(ThemeError("Failed to save grid view preference: ${e.toString()}"));
    }
  }

  Future<void> _onToggleSubtitles(
      ToggleSubtitles event, Emitter<ThemeState> emit) async {
    try {
      final currentState = state;
      if (currentState is ThemeLoaded) {
        final newAppSettings = AppSettings(
          themeMode: currentState.themeMode,
          isGridView: currentState.isGridView,
          subtitlesEnabled: event.subtitlesEnabled,
          videoDecoder: currentState.videoDecoder,
          hardwareAcceleration: currentState.hardwareAcceleration,
        );
        await saveThemeSettings.call(newAppSettings);
        emit(ThemeLoaded(
          themeMode: currentState.themeMode,
          isGridView: currentState.isGridView,
          subtitlesEnabled: event.subtitlesEnabled,
          videoDecoder: currentState.videoDecoder,
          hardwareAcceleration: currentState.hardwareAcceleration,
        ));
      }
    } catch (e) {
      emit(ThemeError("Failed to save subtitle preference: ${e.toString()}"));
    }
  }

  Future<void> _onSetVideoDecoder(
      SetVideoDecoder event, Emitter<ThemeState> emit) async {
    try {
      final currentState = state;
      if (currentState is ThemeLoaded) {
        final newAppSettings = AppSettings(
          themeMode: currentState.themeMode,
          isGridView: currentState.isGridView,
          subtitlesEnabled: currentState.subtitlesEnabled,
          videoDecoder: event.videoDecoder,
          hardwareAcceleration: currentState.hardwareAcceleration,
        );
        await saveThemeSettings.call(newAppSettings);
        emit(ThemeLoaded(
          themeMode: currentState.themeMode,
          isGridView: currentState.isGridView,
          subtitlesEnabled: currentState.subtitlesEnabled,
          videoDecoder: event.videoDecoder,
          hardwareAcceleration: currentState.hardwareAcceleration,
        ));
      }
    } catch (e) {
      emit(ThemeError(
          "Failed to save video decoder preference: ${e.toString()}"));
    }
  }

  Future<void> _onToggleHardwareAcceleration(
      ToggleHardwareAcceleration event, Emitter<ThemeState> emit) async {
    try {
      final currentState = state;
      if (currentState is ThemeLoaded) {
        final newAppSettings = AppSettings(
          themeMode: currentState.themeMode,
          isGridView: currentState.isGridView,
          subtitlesEnabled: currentState.subtitlesEnabled,
          videoDecoder: currentState.videoDecoder,
          hardwareAcceleration: event.hardwareAcceleration,
        );
        await saveThemeSettings.call(newAppSettings);
        emit(ThemeLoaded(
          themeMode: currentState.themeMode,
          isGridView: currentState.isGridView,
          subtitlesEnabled: currentState.subtitlesEnabled,
          videoDecoder: currentState.videoDecoder,
          hardwareAcceleration: event.hardwareAcceleration,
        ));
      }
    } catch (e) {
      emit(ThemeError(
          "Failed to save hardware acceleration preference: ${e.toString()}"));
    }
  }

  // Helper method for direct instantiation as per subtask guideline.
  // In a real app, use GetIt or another proper DI solution.
  static ThemeBloc create() {
    // SettingsLocalDataSourceImpl now fetches SharedPreferences internally.
    final settingsLocalDataSource = SettingsLocalDataSourceImpl();
    final settingsRepository =
        SettingsRepositoryImpl(localDataSource: settingsLocalDataSource);
    final getThemeSettingsUseCase = GetThemeSettings(settingsRepository);
    final saveThemeSettingsUseCase = SaveThemeSettings(settingsRepository);

    return ThemeBloc(
        getThemeSettings: getThemeSettingsUseCase,
        saveThemeSettings: saveThemeSettingsUseCase);
  }
}
