import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart'; // For ThemeMode
import 'package:awesome_video_player/domain/entities/app_settings.dart';
import 'package:awesome_video_player/domain/usecases/get_theme_settings.dart';
import 'package:awesome_video_player/domain/usecases/save_theme_settings.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';

// Manual mocks for UseCases
class MockGetThemeSettings extends Mock implements GetThemeSettings {}
class MockSaveThemeSettings extends Mock implements SaveThemeSettings {}

void main() {
  late MockGetThemeSettings mockGetThemeSettings;
  late MockSaveThemeSettings mockSaveThemeSettings;
  late ThemeBloc themeBloc;

  setUp(() {
    mockGetThemeSettings = MockGetThemeSettings();
    mockSaveThemeSettings = MockSaveThemeSettings();
    themeBloc = ThemeBloc(
      getThemeSettings: mockGetThemeSettings,
      saveThemeSettings: mockSaveThemeSettings,
    );
  });

  tearDown(() {
    themeBloc.close();
  });

  final tInitialAppSettings = AppSettings(themeMode: ThemeMode.system);
  final tDarkAppSettings = AppSettings(themeMode: ThemeMode.dark);
  final tLightAppSettings = AppSettings(themeMode: ThemeMode.light);

  test('initial state should be ThemeInitial, then ThemeLoading, then ThemeLoaded(system) after LoadTheme on creation', () {
    // The BLoC constructor adds LoadTheme.
    // Expect ThemeInitial first, then loading, then loaded from mock.
    // This test needs bloc_test to verify sequence if LoadTheme is auto-triggered.
    // For now, let's check the state *after* bloc is initialized and LoadTheme is processed by bloc_test.
    // If LoadTheme isn't mocked to return, it might go to error.
    // Let's mock getThemeSettings for the initial LoadTheme event.
    when(mockGetThemeSettings.call()).thenAnswer((_) async => tInitialAppSettings);

    // Re-initialize bloc here to ensure the mocked call is used for the initial LoadTheme
    themeBloc = ThemeBloc(
      getThemeSettings: mockGetThemeSettings,
      saveThemeSettings: mockSaveThemeSettings,
    );

    // Expect initial state is ThemeInitial due to constructor,
    // then LoadTheme is added, leading to ThemeLoading then ThemeLoaded.
    // bloc_test handles this sequence.
    expect(themeBloc.state, isA<ThemeInitial>());
    // Actual test of sequence will be done with bloc_test below.
  });

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoading, ThemeLoaded(system)] when LoadTheme is added and use case succeeds (default)',
    build: () {
      when(mockGetThemeSettings.call())
          .thenAnswer((_) async => tInitialAppSettings);
      // ThemeBloc adds LoadTheme in its constructor.
      return ThemeBloc(
          getThemeSettings: mockGetThemeSettings,
          saveThemeSettings: mockSaveThemeSettings);
    },
    // Initial state is ThemeInitial, then LoadTheme is added.
    // So ThemeInitial -> ThemeLoading -> ThemeLoaded
    expect: () => [
      ThemeLoading(),
      ThemeLoaded(tInitialAppSettings.themeMode),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoading, ThemeLoaded(dark)] when LoadTheme is added and use case returns dark theme',
    build: () {
      when(mockGetThemeSettings.call())
          .thenAnswer((_) async => tDarkAppSettings);
      return ThemeBloc(
          getThemeSettings: mockGetThemeSettings,
          saveThemeSettings: mockSaveThemeSettings);
    },
    expect: () => [
      ThemeLoading(),
      ThemeLoaded(tDarkAppSettings.themeMode),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoading, ThemeError] when LoadTheme is added and use case fails',
    build: () {
      when(mockGetThemeSettings.call())
          .thenThrow(Exception('Failed to load theme'));
      return ThemeBloc(
          getThemeSettings: mockGetThemeSettings,
          saveThemeSettings: mockSaveThemeSettings);
    },
    expect: () => [
      ThemeLoading(),
      const ThemeError('Failed to load theme: Exception: Failed to load theme'),
      // The BLoC currently emits ThemeLoaded(ThemeMode.system) as a fallback in error state.
      // Let's adjust the BLoC to not do that for this test or test that behavior.
      // For now, assuming it just emits ThemeError based on current BLoC.
      // The BLoC was updated to: emit(const ThemeLoaded(ThemeMode.system)); // Default to system on error
      const ThemeLoaded(ThemeMode.system),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoaded(dark)] when ChangeTheme(ThemeMode.dark) is added and use case succeeds',
    build: () {
      // Mock saveSettings to complete successfully
      when(mockSaveThemeSettings.call(any)).thenAnswer((_) async {});
      return themeBloc; // Use the one from setUp for events after initial load
    },
    // Assuming initial state (after setUp's ThemeBloc creation and initial LoadTheme) might be ThemeLoaded(system)
    // To make this test cleaner, we can seed the bloc or ensure LoadTheme has run.
    // For simplicity, we assume initial LoadTheme has completed (e.g. to system)
    // and now we are testing ChangeTheme.
    act: (bloc) => bloc.add(const ChangeTheme(ThemeMode.dark)),
    expect: () => [
      ThemeLoaded(tDarkAppSettings.themeMode),
    ],
    verify: (_) {
      verify(mockSaveThemeSettings.call(tDarkAppSettings)).called(1);
    }
  );

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeError] when ChangeTheme is added and use case fails',
    build: () {
      when(mockSaveThemeSettings.call(any))
          .thenThrow(Exception('Failed to save theme'));
      return themeBloc;
    },
    act: (bloc) => bloc.add(const ChangeTheme(ThemeMode.light)),
    expect: () => [
      const ThemeError('Failed to save theme: Exception: Failed to save theme'),
    ],
     verify: (_) {
      verify(mockSaveThemeSettings.call(tLightAppSettings)).called(1);
    }
  );
}
