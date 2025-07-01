import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';
import 'mock_factories.dart';

/// Test helpers for creating test widgets and common test utilities
class TestHelpers {
  /// Creates a test app wrapper with all necessary providers
  static Widget createTestApp({
    required Widget child,
    ThemeBloc? themeBloc,
    VideoListBloc? videoListBloc,
    LastPlayedBloc? lastPlayedBloc,
    FavoritesBloc? favoritesBloc,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => themeBloc ?? MockFactories.createMockThemeBloc(),
        ),
        BlocProvider<VideoListBloc>(
          create: (context) =>
              videoListBloc ?? MockFactories.createMockVideoListBloc(),
        ),
        BlocProvider<LastPlayedBloc>(
          create: (context) =>
              lastPlayedBloc ?? MockFactories.createMockLastPlayedBloc(),
        ),
        BlocProvider<FavoritesBloc>(
          create: (context) =>
              favoritesBloc ?? MockFactories.createMockFavoritesBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Test App',
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        home: child,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  /// Creates a minimal test app for simple widget tests
  static Widget createMinimalTestApp({required Widget child}) {
    return MaterialApp(
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }

  /// Pumps a widget and waits for all animations to complete
  static Future<void> pumpAndSettleWidget(
    WidgetTester tester,
    Widget widget, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(timeout);
  }

  /// Finds a widget by its key
  static Finder findByTestKey(String key) {
    return find.byKey(Key(key));
  }

  /// Taps a widget and waits for the tap to complete
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.tap(finder);
    await tester.pumpAndSettle(timeout);
  }

  /// Enters text into a text field and waits for completion
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle(timeout);
  }

  /// Scrolls a widget and waits for completion
  static Future<void> scrollAndSettle(
    WidgetTester tester,
    Finder finder,
    Offset offset, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle(timeout);
  }

  /// Verifies that a widget exists and is visible
  static void verifyWidgetExists(Finder finder) {
    expect(finder, findsOneWidget);
  }

  /// Verifies that multiple widgets exist
  static void verifyWidgetsExist(Finder finder, int count) {
    expect(finder, findsNWidgets(count));
  }

  /// Verifies that a widget does not exist
  static void verifyWidgetNotExists(Finder finder) {
    expect(finder, findsNothing);
  }

  /// Verifies text content
  static void verifyText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verifies that text contains specific content
  static void verifyTextContains(String partialText) {
    expect(find.textContaining(partialText), findsOneWidget);
  }

  /// Creates a test key for widgets
  static Key createTestKey(String keyName) {
    return Key('test_$keyName');
  }
}
