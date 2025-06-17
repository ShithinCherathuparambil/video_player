import 'package:flutter_bloc/flutter_bloc.dart';
// SharedPreferences import is no longer directly needed here for DI
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/usecases/get_theme_settings.dart';
import 'package:awesome_video_player/domain/usecases/save_theme_settings.dart';
import 'package:awesome_video_player/data/datasources/settings_local_data_source.dart';
import 'package:awesome_video_player/data/repositories/settings_repository_impl.dart';
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

    add(LoadTheme());
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    emit(ThemeLoading());
    try {
      final appSettings = await getThemeSettings.call();
      emit(ThemeLoaded(appSettings.themeMode));
    } catch (e) {
      emit(ThemeError("Failed to load theme: ${e.toString()}"));
      // Fallback to a default theme if loading fails
      emit(const ThemeLoaded(ThemeMode.system)); // Default to system on error
    }
  }

  Future<void> _onChangeTheme(ChangeTheme event, Emitter<ThemeState> emit) async {
    try {
      final newAppSettings = AppSettings(themeMode: event.themeMode);
      await saveThemeSettings.call(newAppSettings);
      emit(ThemeLoaded(event.themeMode));
    } catch (e) {
      emit(ThemeError("Failed to save theme: ${e.toString()}"));
    }
  }

  // Helper method for direct instantiation as per subtask guideline.
  // In a real app, use GetIt or another proper DI solution.
  static ThemeBloc create() {
    // SettingsLocalDataSourceImpl now fetches SharedPreferences internally.
    final settingsLocalDataSource = SettingsLocalDataSourceImpl();
    final settingsRepository = SettingsRepositoryImpl(localDataSource: settingsLocalDataSource);
    final getThemeSettingsUseCase = GetThemeSettings(settingsRepository);
    final saveThemeSettingsUseCase = SaveThemeSettings(settingsRepository);

    return ThemeBloc(
        getThemeSettings: getThemeSettingsUseCase,
        saveThemeSettings: saveThemeSettingsUseCase
    );
  }
}
