import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/domain/usecases/get_videos.dart';
import 'package:lumeo/domain/usecases/save_video_metadata.dart';
import 'package:lumeo/domain/usecases/toggle_favorite.dart' as domain_toggle;
import 'package:lumeo/domain/usecases/get_favorite_videos.dart';
import 'package:lumeo/domain/usecases/get_theme_settings.dart';
import 'package:lumeo/domain/usecases/save_theme_settings.dart';
import 'package:lumeo/domain/usecases/toggle_authentication.dart'
    as auth_usecase;
import 'package:lumeo/domain/repositories/video_repository.dart';
import 'package:lumeo/domain/repositories/settings_repository.dart';
import 'package:lumeo/data/datasources/video_local_data_source.dart';
import 'package:lumeo/data/datasources/settings_local_data_source.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_state.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_event.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_state.dart';
import 'package:lumeo/presentation/blocs/video_player_cubit/video_player_cubit.dart';
import 'package:lumeo/presentation/blocs/video_player_cubit/video_player_state.dart';

// Mock classes for use cases
class MockGetVideos extends Mock implements GetVideos {
  @override
  Future<List<VideoFile>> call({int? page, int? pageSize}) =>
      super.noSuchMethod(
        Invocation.method(#call, [], {#page: page, #pageSize: pageSize}),
        returnValue: Future.value(<VideoFile>[]),
      );
}

class MockSaveVideoMetadata extends Mock implements SaveVideoMetadata {}

class MockToggleFavorite extends Mock implements domain_toggle.ToggleFavorite {}

class MockGetFavoriteVideos extends Mock implements GetFavoriteVideos {}

class MockGetThemeSettings extends Mock implements GetThemeSettings {}

class MockSaveThemeSettings extends Mock implements SaveThemeSettings {}

class MockToggleAuthentication extends Mock
    implements auth_usecase.ToggleAuthentication {}

// Mock classes for repositories
class MockVideoRepository extends Mock implements VideoRepository {
  @override
  Future<void> saveVideoMetadata(VideoFile? video) => super.noSuchMethod(
        Invocation.method(#saveVideoMetadata, [video]),
        returnValue: Future<void>.value(),
      );
}

class MockSettingsRepository extends Mock implements SettingsRepository {
  @override
  Future<AppSettings> getSettings() => super.noSuchMethod(
        Invocation.method(#getSettings, []),
        returnValue: Future.value(AppSettings(themeMode: ThemeMode.system)),
      );

  @override
  Future<void> saveSettings(AppSettings? settings) => super.noSuchMethod(
        Invocation.method(#saveSettings, [settings]),
        returnValue: Future<void>.value(),
      );
}

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
    when(mock.call(page: anyNamed('page'), pageSize: anyNamed('pageSize')))
        .thenAnswer((_) async => createTestVideoList());
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

  static MockToggleAuthentication createMockToggleAuthentication() {
    return MockToggleAuthentication();
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
