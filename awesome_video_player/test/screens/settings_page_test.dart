import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_video_player/logic/providers/theme_provider.dart';
import 'package:awesome_video_player/presentation/screens/settings_page.dart';
import 'package:awesome_video_player/presentation/theme/app_themes.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPage Widget Tests', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      // Mock SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      // Ensure ThemeProvider finishes loading preferences
      await Future.delayed(Duration.zero);
    });

    Widget createTestableWidget(Widget child) {
      return ChangeNotifierProvider<ThemeProvider>.value(
        value: themeProvider,
        child: MaterialApp(
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: Builder(builder: (context) {
            // Rebuild MaterialApp when themeMode changes by listening to themeProvider
            final currentThemeProvider = Provider.of<ThemeProvider>(context);
            return MaterialApp(
              theme: AppThemes.lightTheme,
              darkTheme: AppThemes.darkTheme,
              themeMode: currentThemeProvider.themeMode,
              home: child,
            );
          }),
        ),
      );
    }

    testWidgets('Displays "Dark Mode" text and a Switch', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const SettingsPage()));

      expect(find.text('Settings'), findsOneWidget); // AppBar title
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('Switch reflects ThemeProvider state and calls toggleTheme', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const SettingsPage()));

      // Check initial state of the switch (should be light/false based on default ThemeProvider)
      Switch darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, false); // Assuming default is light

      // Simulate tapping the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle(); // Rebuild with new theme state

      // Verify ThemeProvider was called and state changed
      expect(themeProvider.isDarkMode, true);

      // Verify Switch UI updated
      darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, true);

      // Tap again to toggle back
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, false);
      darkModeSwitch = tester.widget(find.byType(Switch));
      expect(darkModeSwitch.value, false);
    });

     testWidgets('Theme changes when switch is toggled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(const SettingsPage()));

      // Initial theme should be light
      expect(themeProvider.themeMode, ThemeMode.light); // Or system, depending on default load

      // Tap the switch to enable dark mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle(); // Let provider notify and widget rebuild

      // Verify theme is now dark
      expect(themeProvider.themeMode, ThemeMode.dark);

      // Check a Material widget to see if dark theme is applied (e.g., Scaffold background)
      // This requires the MaterialApp in createTestableWidget to correctly use themeMode.
      Scaffold scaffold = tester.widget(find.byType(Scaffold).first);
      // Note: Direct color comparison can be brittle. Checking themeMode is more robust.
      // For this test, relying on themeProvider.themeMode is the primary check.
      // If you wanted to check actual color, you'd need to know the specific color from AppThemes.darkTheme.
      // For instance: expect(scaffold.backgroundColor, AppThemes.darkTheme.scaffoldBackgroundColor);
      // This also depends on SettingsPage's Scaffold not overriding its background.

      // Tap the switch to disable dark mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify theme is now light
      expect(themeProvider.themeMode, ThemeMode.light);
    });
  });
}
