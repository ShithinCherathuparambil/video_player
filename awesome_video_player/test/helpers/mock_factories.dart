import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/usecases/get_videos.dart';
import 'package:awesome_video_player/domain/usecases/save_video_metadata.dart';
import 'package:awesome_video_player/domain/usecases/toggle_favorite.dart'
    as domain_toggle;
import 'package:awesome_video_player/domain/usecases/get_favorite_videos.dart';
import 'package:awesome_video_player/domain/usecases/get_theme_settings.dart';
import 'package:awesome_video_player/domain/usecases/save_theme_settings.dart';
import 'package:awesome_video_player/domain/repositories/video_repository.dart';
import 'package:awesome_video_player/domain/repositories/settings_repository.dart';
import 'package:awesome_video_player/data/datasources/video_local_data_source.dart';
import 'package:awesome_video_player/data/datasources/settings_local_data_source.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_state.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_event.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_state.dart';
import 'package:awesome_video_player/presentation/blocs/video_player_cubit/video_player_cubit.dart';
import 'package:awesome_video_player/presentation/blocs/video_player_cubit/video_player_state.dart';

// Mock classes for use cases
class MockGetVideos extends Mock implements GetVideos {}

class MockSaveVideoMetadata extends Mock implements SaveVideoMetadata {}

class MockToggleFavorite extends Mock implements domain_toggle.ToggleFavorite {}

class MockGetFavoriteVideos extends Mock implements GetFavoriteVideos {}

class MockGetThemeSettings extends Mock implements GetThemeSettings {}

class MockSaveThemeSettings extends Mock implements SaveThemeSettings {}

// Mock classes for repositories
class MockVideoRepository extends Mock implements VideoRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

// Mock classes for data sources
class MockVideoLocalDataSource extends Mock implements VideoLocalDataSource {}

class MockSettingsLocalDataSource extends Mock
    implements SettingsLocalDataSource {}

// Mock classes for BLoCs
class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

class MockVideoListBloc extends MockBloc<VideoListEvent, VideoListState>
    implements VideoListBloc {}

class MockLastPlayedBloc extends MockBloc<LastPlayedEvent, LastPlayedState>
    implements LastPlayedBloc {}

class MockFavoritesBloc extends MockBloc<FavoritesEvent, FavoritesState>
    implements FavoritesBloc {}

class MockVideoPlayerCubit extends MockCubit<VideoPlayerControlsState>
    implements VideoPlayerCubit {}

/// Factory class for creating mock objects and test data
class MockFactories {
  // Test data creation methods
  static VideoFile createTestVideoFile({
    String? path,
    String? name,
    String? thumbnailPath,
    Duration? duration,
    int? fileSize,
    DateTime? dateAdded,
    Duration? lastPlayedPosition,
    DateTime? lastPlayedAt,
    VideoStatus? status,
    bool? isFavorite,
  }) {
    return VideoFile(
      path: path ?? '/test/video.mp4',
      name: name ?? 'Test Video',
      thumbnailPath: thumbnailPath ?? '/test/thumbnail.jpg',
      duration: duration ?? const Duration(minutes: 5),
      fileSize: fileSize ?? 1024000,
      dateAdded: dateAdded ?? DateTime.now(),
      lastPlayedPosition: lastPlayedPosition ?? Duration.zero,
      lastPlayedAt: lastPlayedAt,
      status: status ?? VideoStatus.new_,
      isFavorite: isFavorite ?? false,
    );
  }

  static List<VideoFile> createTestVideoList({int count = 3}) {
    return List.generate(
        count,
        (index) => createTestVideoFile(
              path: '/test/video_$index.mp4',
              name: 'Test Video $index',
              thumbnailPath: '/test/thumbnail_$index.jpg',
            ));
  }

  static AppSettings createTestAppSettings({
    ThemeMode? themeMode,
    bool? isGridView,
    bool? subtitlesEnabled,
    String? videoDecoder,
    bool? hardwareAcceleration,
  }) {
    return AppSettings(
      themeMode: themeMode ?? ThemeMode.system,
      isGridView: isGridView ?? true,
      subtitlesEnabled: subtitlesEnabled ?? false,
      videoDecoder: videoDecoder ?? 'auto',
      hardwareAcceleration: hardwareAcceleration ?? true,
    );
  }

  // Mock BLoC creation methods
  static MockThemeBloc createMockThemeBloc() {
    final mockBloc = MockThemeBloc();
    whenListen(
      mockBloc,
      Stream.fromIterable([
        const ThemeLoaded(themeMode: ThemeMode.system),
      ]),
      initialState: ThemeInitial(),
    );
    return mockBloc;
  }

  static MockVideoListBloc createMockVideoListBloc() {
    final mockBloc = MockVideoListBloc();
    whenListen(
      mockBloc,
      Stream.fromIterable([
        VideoListLoaded(createTestVideoList()),
      ]),
      initialState: const VideoListInitial(),
    );
    return mockBloc;
  }

  static MockLastPlayedBloc createMockLastPlayedBloc() {
    final mockBloc = MockLastPlayedBloc();
    whenListen(
      mockBloc,
      Stream.fromIterable([
        LastPlayedInitial(),
      ]),
      initialState: LastPlayedInitial(),
    );
    return mockBloc;
  }

  static MockFavoritesBloc createMockFavoritesBloc() {
    final mockBloc = MockFavoritesBloc();
    whenListen(
      mockBloc,
      Stream.fromIterable([
        FavoritesLoaded(
            createTestVideoList().where((v) => v.isFavorite).toList()),
      ]),
      initialState: FavoritesInitial(),
    );
    return mockBloc;
  }

  static MockVideoPlayerCubit createMockVideoPlayerCubit() {
    final mockCubit = MockVideoPlayerCubit();
    whenListen(
      mockCubit,
      Stream.fromIterable([
        const VideoPlayerControlsVisibilityChanged(true),
      ]),
      initialState: const VideoPlayerControlsVisibilityChanged(true),
    );
    return mockCubit;
  }

  // Mock use case creation methods
  static MockGetVideos createMockGetVideos() {
    final mock = MockGetVideos();
    when(mock.call()).thenAnswer((_) async => createTestVideoList());
    return mock;
  }

  static MockSaveVideoMetadata createMockSaveVideoMetadata() {
    return MockSaveVideoMetadata();
  }

  static MockToggleFavorite createMockToggleFavorite() {
    return MockToggleFavorite();
  }

  static MockGetFavoriteVideos createMockGetFavoriteVideos() {
    final mock = MockGetFavoriteVideos();
    when(mock.call()).thenAnswer(
        (_) async => createTestVideoList().where((v) => v.isFavorite).toList());
    return mock;
  }

  static MockGetThemeSettings createMockGetThemeSettings() {
    final mock = MockGetThemeSettings();
    when(mock.call()).thenAnswer((_) async => createTestAppSettings());
    return mock;
  }

  static MockSaveThemeSettings createMockSaveThemeSettings() {
    return MockSaveThemeSettings();
  }

  // Mock repository creation methods
  static MockVideoRepository createMockVideoRepository() {
    return MockVideoRepository();
  }

  static MockSettingsRepository createMockSettingsRepository() {
    return MockSettingsRepository();
  }

  // Mock data source creation methods
  static MockVideoLocalDataSource createMockVideoLocalDataSource() {
    return MockVideoLocalDataSource();
  }

  static MockSettingsLocalDataSource createMockSettingsLocalDataSource() {
    return MockSettingsLocalDataSource();
  }
}
