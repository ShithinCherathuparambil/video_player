import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_event.dart';
import 'package:awesome_video_player/presentation/blocs/favorites_bloc/favorites_state.dart';
import 'package:awesome_video_player/presentation/screens/video_player_page.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/last_played_bloc/last_played_event.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    // Refresh favorites when page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesBloc>().add(const RefreshFavorites());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FavoritesBloc>().add(const RefreshFavorites());
            },
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading favorites...'),
                ],
              ),
            );
          } else if (state is FavoritesLoaded) {
            if (state.favorites.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Double-tap videos to add them to favorites',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FavoritesBloc>().add(const RefreshFavorites());
              },
              child: ListView.builder(
                itemCount: state.favorites.length,
                itemBuilder: (context, index) {
                  final video = state.favorites[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: video.thumbnailPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(video.thumbnailPath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.play_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                      ),
                      title: Text(
                        video.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (video.duration != null)
                            Text(
                              'Duration: ${_formatDuration(video.duration!)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (video.fileSize != null)
                            Text(
                              'Size: ${_formatFileSize(video.fileSize!)}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.favorite,
                        color: Colors.red,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerPage(
                              video: video,
                              resumeFromLastPosition:
                                  video.lastPlayedPosition != null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          } else if (state is FavoritesEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Double-tap videos to add them to favorites',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          } else if (state is FavoritesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading favorites',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<FavoritesBloc>()
                          .add(const RefreshFavorites());
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Loading...'));
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
