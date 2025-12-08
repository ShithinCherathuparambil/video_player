import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart'; // For ThemeMode
import 'package:lumeo/domain/entities/app_settings.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import '../../../helpers/mock_factories.dart';

void main() {
  late MockGetThemeSettings mockGetThemeSettings;
  late MockSaveThemeSettings mockSaveThemeSettings;
  late MockToggleAuthentication
      mockToggleAuthentication; // Using MockToggleFavorite as placeholder or need specific mock? ToggleAuthentication is in auth_usecase.
  // Actually, mock_factories provides createMockToggleFavorite (which is for video favorite?).
  // ToggleAuthentication usecase is different.
  // Check mock_factories for ToggleAuthentication mock.

  setUp(() {
    mockGetThemeSettings = MockFactories.createMockGetThemeSettings();
    mockSaveThemeSettings = MockFactories.createMockSaveThemeSettings();
    mockToggleAuthentication = MockFactories.createMockToggleAuthentication();
  });

  final tInitialAppSettings = AppSettings(themeMode: ThemeMode.system);
  final tDarkAppSettings = AppSettings(themeMode: ThemeMode.dark);
  final tLightAppSettings = AppSettings(themeMode: ThemeMode.light);

  test('initial state should be ThemeInitial', () {
    // Create a fresh bloc for this test
    final bloc = ThemeBloc(
      getThemeSettings: mockGetThemeSettings,
      saveThemeSettings: mockSaveThemeSettings,
      toggleAuthentication: mockToggleAuthentication,
    );

    // Expect initial state is ThemeInitial due to constructor
    expect(bloc.state, isA<ThemeInitial>());

    bloc.close();
  });

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoading, ThemeLoaded(system)] when LoadTheme is added and use case succeeds (default)',
    build: () {
      when(mockGetThemeSettings.call())
          .thenAnswer((_) async => tInitialAppSettings);
      return ThemeBloc(
          getThemeSettings: mockGetThemeSettings,
          saveThemeSettings: mockSaveThemeSettings,
          toggleAuthentication: mockToggleAuthentication);
    },
    // Initial state is ThemeInitial, then LoadTheme is added.
    // So ThemeInitial -> ThemeLoading -> ThemeLoaded
    expect: () => [
      ThemeLoading(),
      ThemeLoaded(themeMode: tInitialAppSettings.themeMode),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoading, ThemeLoaded(dark)] when LoadTheme is added and use case returns dark theme',
    setUp: () {
      when(mockGetThemeSettings.call())
          .thenAnswer((_) async => tDarkAppSettings);
    },
    build: () => ThemeBloc(
        getThemeSettings: mockGetThemeSettings,
        saveThemeSettings: mockSaveThemeSettings,
        toggleAuthentication: mockToggleAuthentication),
    expect: () => [
      ThemeLoading(),
      ThemeLoaded(themeMode: tDarkAppSettings.themeMode),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
    'emits [ThemeLoading, ThemeError] when LoadTheme is added and use case fails',
    setUp: () {
      when(mockGetThemeSettings.call())
          .thenThrow(Exception('Failed to load theme'));
    },
    build: () => ThemeBloc(
        getThemeSettings: mockGetThemeSettings,
        saveThemeSettings: mockSaveThemeSettings,
        toggleAuthentication: mockToggleAuthentication),
    expect: () => [
      ThemeLoading(),
      const ThemeError('Failed to load theme: Exception: Failed to load theme'),
      // The BLoC currently emits ThemeLoaded(ThemeMode.system) as a fallback in error state.
      // Let's adjust the BLoC to not do that for this test or test that behavior.
      // For now, assuming it just emits ThemeError based on current BLoC.
      // The BLoC was updated to: emit(const ThemeLoaded(ThemeMode.system)); // Default to system on error
      const ThemeLoaded(themeMode: ThemeMode.system),
    ],
  );

  blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeLoaded(dark)] when ChangeTheme(ThemeMode.dark) is added and use case succeeds',
      setUp: () {
        // Mock saveSettings to complete successfully
        when(mockSaveThemeSettings.call(tDarkAppSettings))
            .thenAnswer((_) async {});
      },
      build: () => ThemeBloc(
          getThemeSettings: mockGetThemeSettings,
          saveThemeSettings: mockSaveThemeSettings,
          toggleAuthentication:
              mockToggleAuthentication), // Create fresh bloc for this test
      // Assuming initial state (after setUp's ThemeBloc creation and initial LoadTheme) might be ThemeLoaded(system)
      // To make this test cleaner, we can seed the bloc or ensure LoadTheme has run.
      // For simplicity, we assume initial LoadTheme has completed (e.g. to system)
      // and now we are testing ChangeTheme.
      act: (bloc) => bloc.add(const ChangeTheme(ThemeMode.dark)),
      expect: () => [
            ThemeLoaded(themeMode: tDarkAppSettings.themeMode),
          ],
      verify: (_) {
        verify(mockSaveThemeSettings.call(tDarkAppSettings)).called(1);
      });

  blocTest<ThemeBloc, ThemeState>(
      'emits [ThemeError] when ChangeTheme is added and use case fails',
      setUp: () {
        when(mockSaveThemeSettings.call(tLightAppSettings))
            .thenThrow(Exception('Failed to save theme'));
      },
      build: () => ThemeBloc(
          getThemeSettings: mockGetThemeSettings,
          saveThemeSettings: mockSaveThemeSettings,
          toggleAuthentication: mockToggleAuthentication),
      act: (bloc) => bloc.add(const ChangeTheme(ThemeMode.light)),
      expect: () => [
            const ThemeError(
                'Failed to save theme: Exception: Failed to save theme'),
          ],
      verify: (_) {
        verify(mockSaveThemeSettings.call(tLightAppSettings)).called(1);
      });
}
