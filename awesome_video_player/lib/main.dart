import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_bloc.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_event.dart';
import 'package:lumeo/presentation/blocs/theme_bloc/theme_state.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:lumeo/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:lumeo/presentation/theme/app_themes.dart';
import 'package:lumeo/presentation/screens/splash_screen.dart';
import 'package:lumeo/core/services/bloc_communication_service.dart';
import 'package:lumeo/core/services/video_cache_service.dart';
import 'package:photo_manager/photo_manager.dart';

// Global navigator key for overlay access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress known BetterPlayer subtitle drawer setState error during disposal
  // This is a harmless error that occurs when BetterPlayer's dispose() calls pause()
  // which triggers the subtitle drawer to update during widget tree disposal
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionString = details.exception.toString();
    final stackString = details.stack?.toString() ?? '';

    // Suppress the specific BetterPlayer subtitle drawer setState error
    if ((exceptionString.contains(
                'setState() or markNeedsBuild() called when widget tree was locked') ||
            exceptionString.contains('widget tree was locked')) &&
        (stackString.contains('BetterPlayerSubtitlesDrawer') ||
            stackString.contains('better_player_subtitles_drawer'))) {
      // This is a known BetterPlayer issue - ignore it silently
      // The error is harmless and doesn't affect functionality
      debugPrint(
          'Suppressed BetterPlayer subtitle drawer setState error during disposal (known issue)');
      return;
    }

    // Handle all other errors normally
    FlutterError.presentError(details);
  };

  // Initialize video cache service
  try {
    await VideoCacheService.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize video cache service: $e');
  }

  // Request storage permissions early
  try {
    await PhotoManager.requestPermissionExtend();
  } catch (e) {
    debugPrint('Failed to request permissions at startup: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // Clean up BLoC communication service
    BlocCommunicationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<ThemeBloc>(
              create: (context) => ThemeBloc.create()..add(LoadTheme()),
            ),
            BlocProvider<VideoListBloc>(
              create: (context) {
                final bloc = VideoListBloc.create();
                BlocCommunicationService.registerVideoListBloc(bloc);
                return bloc;
              },
            ),
            BlocProvider<LastPlayedBloc>(
              create: (context) => LastPlayedBloc.create(),
            ),
            BlocProvider<FavoritesBloc>(
              create: (context) {
                final bloc = FavoritesBloc.create();
                BlocCommunicationService.registerFavoritesBloc(bloc);
                return bloc;
              },
            ),
          ],
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                title: 'Lumeo Player',
                theme: AppThemes.lightTheme,
                darkTheme: AppThemes.darkTheme,
                themeMode: themeState is ThemeLoaded
                    ? themeState.themeMode
                    : ThemeMode.system,
                home: const SplashScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          ),
        );
      },
    );
  }
}
