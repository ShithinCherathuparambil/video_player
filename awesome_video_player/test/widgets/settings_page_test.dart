import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:lumeo/presentation/screens/settings_page.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import '../helpers/test_helpers.dart';
import '../helpers/mock_factories.dart';

void main() {
  group('SettingsPage Widget Tests', () {
    late MockThemeBloc mockThemeBloc;

    setUp(() {
      mockThemeBloc = MockFactories.createMockThemeBloc();
    });

    Widget createTestWidget() {
      return BlocProvider<ThemeBloc>.value(
        value: mockThemeBloc,
        child: const MaterialApp(
          home: SettingsPage(),
        ),
      );
    }

    testWidgets('should display app bar with title',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should display theme settings section',
        (WidgetTester tester) async {
      // Mock theme loaded state
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(themeMode: ThemeMode.system)]),
        initialState: const ThemeLoaded(themeMode: ThemeMode.system),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('should display theme mode options',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(themeMode: ThemeMode.system)]),
        initialState: const ThemeLoaded(themeMode: ThemeMode.system),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check for theme mode options
      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('System Theme'), findsOneWidget);
    });

    testWidgets('should handle theme mode selection',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(themeMode: ThemeMode.system)]),
        initialState: const ThemeLoaded(themeMode: ThemeMode.system),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find and tap light theme option
      final lightThemeOption = find.text('Light Theme');
      expect(lightThemeOption, findsOneWidget);
      await tester.tap(lightThemeOption);
      await tester.pump();

      // Bloc event would be verified in unit tests
    });

    testWidgets('should display view preferences section',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(
            themeMode: ThemeMode.system,
            isGridView: true,
          )
        ]),
        initialState: const ThemeLoaded(
          themeMode: ThemeMode.system,
          isGridView: true,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Grid View is in the Appearance section
      expect(find.text('Grid View'), findsOneWidget);
    });

    testWidgets('should handle grid view toggle', (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(
            themeMode: ThemeMode.system,
            isGridView: true,
          )
        ]),
        initialState: const ThemeLoaded(
          themeMode: ThemeMode.system,
          isGridView: true,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find grid view switch
      final gridViewSwitch = find.byType(Switch);
      expect(gridViewSwitch, findsOneWidget);

      // Verify switch is on (grid view enabled)
      final switchWidget = tester.widget<Switch>(gridViewSwitch);
      expect(switchWidget.value, true);

      // Tap to toggle
      await tester.tap(gridViewSwitch);
      await tester.pump();
    });

    testWidgets('should display playback settings section',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(
            themeMode: ThemeMode.system,
            subtitlesEnabled: false,
            hardwareAcceleration: true,
          )
        ]),
        initialState: const ThemeLoaded(
          themeMode: ThemeMode.system,
          subtitlesEnabled: false,
          hardwareAcceleration: true,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Video section contains these settings
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Subtitles'), findsOneWidget);
      expect(find.text('Hardware Acceleration'), findsOneWidget);
    });

    testWidgets('should handle subtitles toggle', (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(
            themeMode: ThemeMode.system,
            subtitlesEnabled: false,
          )
        ]),
        initialState: const ThemeLoaded(
          themeMode: ThemeMode.system,
          subtitlesEnabled: false,
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find subtitles switch
      final subtitlesText = find.text('Subtitles');
      expect(subtitlesText, findsOneWidget);

      // Find the switch associated with subtitles
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);

      // Tap the first switch (assuming it's subtitles)
      await tester.tap(switches.first);
      await tester.pump();
    });

    testWidgets('should display video decoder settings',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(
            themeMode: ThemeMode.system,
            videoDecoder: 'auto',
          )
        ]),
        initialState: const ThemeLoaded(
          themeMode: ThemeMode.system,
          videoDecoder: 'auto',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Video Decoder'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('should handle video decoder selection',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([
          const ThemeLoaded(
            themeMode: ThemeMode.system,
            videoDecoder: 'auto',
          )
        ]),
        initialState: const ThemeLoaded(
          themeMode: ThemeMode.system,
          videoDecoder: 'auto',
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Find dropdown for video decoder
      final dropdown = find.byType(DropdownButton<String>);
      expect(dropdown, findsOneWidget);

      // Tap to open dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Should show decoder options
      expect(find.text('Hardware'), findsOneWidget);
      expect(find.text('Software'), findsOneWidget);
    });

    testWidgets('should have proper accessibility',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(themeMode: ThemeMode.system)]),
        initialState: const ThemeLoaded(themeMode: ThemeMode.system),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify semantic structure
      expect(find.byType(Semantics), findsWidgets);

      // Check accessibility guidelines
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('should handle back navigation', (WidgetTester tester) async {
      // Create a navigation context for the back button to appear
      await tester.pumpWidget(
        BlocProvider<ThemeBloc>.value(
          value: mockThemeBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  ),
                  child: const Text('Go to Settings'),
                ),
              ),
            ),
          ),
        ),
      );

      // Navigate to settings
      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      // Now there should be a back button
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('should display settings in scrollable view',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(themeMode: ThemeMode.system)]),
        initialState: const ThemeLoaded(themeMode: ThemeMode.system),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify scrollable content
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should handle different screen orientations',
        (WidgetTester tester) async {
      whenListen(
        mockThemeBloc,
        Stream.fromIterable([const ThemeLoaded(themeMode: ThemeMode.system)]),
        initialState: const ThemeLoaded(themeMode: ThemeMode.system),
      );

      // Test portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);

      // Test landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pump();
      expect(find.text('Settings'), findsOneWidget);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });
  });
}
