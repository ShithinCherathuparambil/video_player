import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart'; // For MockBloc
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:awesome_video_player/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:awesome_video_player/presentation/screens/settings_page.dart';
import 'package:awesome_video_player/presentation/theme/app_themes.dart'; // For MaterialApp theming

// Mock ThemeBloc for widget tests
class MockThemeBloc extends MockBloc<ThemeEvent, ThemeState> implements ThemeBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // Ensure bindings for tests

  late MockThemeBloc mockThemeBloc;

  setUp(() {
    mockThemeBloc = MockThemeBloc();
  });

  Widget createTestableWidget(Widget child) {
    return BlocProvider<ThemeBloc>.value(
      value: mockThemeBloc,
      child: MaterialApp( // Outer MaterialApp for theme context
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        // This inner MaterialApp will rebuild based on ThemeBloc state via BlocBuilder
        home: BlocBuilder<ThemeBloc, ThemeState>(
          bloc: mockThemeBloc, // Use the same mock bloc
          builder: (context, state) {
            ThemeMode currentThemeMode = ThemeMode.system;
            if (state is ThemeLoaded) {
              currentThemeMode = state.themeMode;
            }
            return MaterialApp( // Inner MaterialApp to apply the themeMode
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: currentThemeMode,
              home: child,
            );
          },
        ),
      ),
    );
  }

  group('SettingsPage Widget Tests with MockThemeBloc', () {
    testWidgets('Displays "Dark Mode" text and a Switch', (WidgetTester tester) async {
      // Arrange: Initial state from BLoC will be ThemeMode.system (or light by default if ThemeInitial is handled that way)
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(ThemeMode.light)]), // Initial state for the switch
        initialState: const ThemeLoaded(ThemeMode.light), // Default to light for the switch
      );

      await tester.pumpWidget(createTestableWidget(const SettingsPage()));

      expect(find.text('Settings'), findsOneWidget); // AppBar title
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Switch reflects ThemeBloc state (light mode)', (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(ThemeMode.light)]),
        initialState: const ThemeLoaded(ThemeMode.light),
      );

      await tester.pumpWidget(createTestableWidget(const SettingsPage()));
      await tester.pumpAndSettle(); // Ensure BlocBuilder has built

      final Switch darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, false); // isDarkMode is false for ThemeMode.light
    });

    testWidgets('Switch reflects ThemeBloc state (dark mode)', (WidgetTester tester) async {
       whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(ThemeMode.dark)]),
        initialState: const ThemeLoaded(ThemeMode.dark),
      );

      await tester.pumpWidget(createTestableWidget(const SettingsPage()));
      await tester.pumpAndSettle();

      final Switch darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, true); // isDarkMode is true for ThemeMode.dark
    });

    testWidgets('Tapping Switch dispatches ChangeTheme event to ThemeBloc', (WidgetTester tester) async {
      // Arrange: Start with light theme state
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(ThemeMode.light), // Initial
          const ThemeLoaded(ThemeMode.dark)   // After tap
        ]),
        initialState: const ThemeLoaded(ThemeMode.light),
      );

      await tester.pumpWidget(createTestableWidget(const SettingsPage()));
      await tester.pumpAndSettle();


      // Act: Tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle(); // Allow BLoC to process and UI to update

      // Assert: Verify ChangeTheme event was added to the BLoC
      // The actual event dispatched by the UI is ChangeTheme(ThemeMode.dark)
      // because initial state is light (isDarkMode=false), switch sends true, which maps to ThemeMode.dark
      verify(() => mockThemeBloc.add(const ChangeTheme(ThemeMode.dark))).called(1);

      // Also check if switch reflects the new state (optional, as bloc_test handles state changes)
      final Switch darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, true); // Assuming BLoC correctly updated its state
    });

    testWidgets('Tapping Switch from dark to light dispatches ChangeTheme event', (WidgetTester tester) async {
      // Arrange: Start with dark theme state
       whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(ThemeMode.dark),   // Initial
          const ThemeLoaded(ThemeMode.light)  // After tap
        ]),
        initialState: const ThemeLoaded(ThemeMode.dark),
      );

      await tester.pumpWidget(createTestableWidget(const SettingsPage()));
      await tester.pumpAndSettle();

      // Act: Tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Assert: Verify ChangeTheme event was added
      verify(() => mockThemeBloc.add(const ChangeTheme(ThemeMode.light))).called(1);

      final Switch darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, false);
    });
  });
}
