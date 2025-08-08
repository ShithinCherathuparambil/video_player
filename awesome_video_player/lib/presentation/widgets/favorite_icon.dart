import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:lumeo/presentation/blocs/video_list_bloc/video_list_state.dart';

/// A reusable favorite icon widget that only rebuilds when the specific video's favorite status changes
class FavoriteIcon extends StatelessWidget {
  final VideoFile video;
  final double size;
  final EdgeInsets padding;
  final bool showInFavorites;

  const FavoriteIcon({
    super.key,
    required this.video,
    this.size = 12,
    this.padding = const EdgeInsets.all(4),
    this.showInFavorites = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoListBloc, VideoListState>(
      buildWhen: (previous, current) {
        // Always rebuild on VideoListLoaded state changes
        final shouldRebuild = current is VideoListLoaded;
        debugPrint(
            'FavoriteIcon: Video ${video.path} - ShouldRebuild: $shouldRebuild (State: ${current.runtimeType})');
        return shouldRebuild;
      },
      builder: (context, state) {
        debugPrint(
            'FavoriteIcon: Video ${video.path} - Building with state: ${state.runtimeType}');
        if (state is VideoListLoaded) {
          final currentVideo = state.videos.firstWhere(
            (v) => v.path == video.path,
            orElse: () => video,
          );

          debugPrint(
              'FavoriteIcon: Video ${video.path} - Current favorite status: ${currentVideo.isFavorite}, ShowInFavorites: $showInFavorites');

          // In favorites page, only show if still in favorites
          if (showInFavorites && !currentVideo.isFavorite) {
            debugPrint(
                'FavoriteIcon: Video ${video.path} - Hiding in favorites page');
            return const SizedBox.shrink();
          }

          // In main list, show if favorite
          if (!showInFavorites && !currentVideo.isFavorite) {
            debugPrint(
                'FavoriteIcon: Video ${video.path} - Hiding in main list');
            return const SizedBox.shrink();
          }

          debugPrint(
              'FavoriteIcon: Video ${video.path} - Showing favorite icon');
          return Positioned(
            bottom: 8,
            right: showInFavorites ? 8 : 4,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: size,
              ),
            ),
          );
        }
        debugPrint(
            'FavoriteIcon: Video ${video.path} - State is not VideoListLoaded');
        return const SizedBox.shrink();
      },
    );
  }
}
