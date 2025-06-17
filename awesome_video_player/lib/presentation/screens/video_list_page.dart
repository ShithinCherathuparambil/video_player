import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:awesome_video_player/domain/entities/video_file.dart'; // For VideoFile entity
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_bloc.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_event.dart';
import 'package:awesome_video_player/presentation/blocs/video_list_bloc/video_list_state.dart';
import './video_player_page.dart';
import './settings_page.dart';

class VideoListPage extends StatelessWidget { // Changed to StatelessWidget
  const VideoListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VideoListBloc.create()..add(LoadVideos()), // Create BLoC and load initial videos
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Videos'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            // Optional: Add a refresh button to dispatch LoadVideos again
            // BlocBuilder<VideoListBloc, VideoListState>(
            //   builder: (context, state) {
            //     if (state is VideoListLoading) return Container(); // Don't show refresh if loading
            //     return IconButton(
            //       icon: const Icon(Icons.refresh),
            //       onPressed: () {
            //         context.read<VideoListBloc>().add(LoadVideos());
            //       },
            //     );
            //   },
            // ),
          ],
        ),
        body: const VideoListContent(), // Extracted content to a new widget
      ),
    );
  }
}

class VideoListContent extends StatelessWidget {
  const VideoListContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoListBloc, VideoListState>(
      builder: (context, state) {
        if (state is VideoListLoading || state is VideoListInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is VideoListLoaded) {
          if (state.videos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No videos found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: (){
                             context.read<VideoListBloc>().add(LoadVideos());
                        }
                    )
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              final VideoFile videoFile = state.videos[index]; // Use VideoFile entity
              return ListTile(
                leading: const Icon(Icons.movie_creation_outlined, size: 40),
                title: Text(videoFile.name), // Use name from entity
                subtitle: Text(videoFile.path), // Use path from entity
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoPlayerPage(videoPath: videoFile.path),
                    ),
                  );
                },
              );
            },
          );
        } else if (state is VideoListPermissionDenied) {
           return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.orange),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    child: const Text('Retry Permissions / Load'),
                    onPressed: () {
                      context.read<VideoListBloc>().add(LoadVideos());
                    },
                  )
                ],
              ),
            ),
          );
        }
        else if (state is VideoListError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
               child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: (){
                             context.read<VideoListBloc>().add(LoadVideos());
                        }
                    )
                ],
              ),
            ),
          );
        }
        return const Center(child: Text('Something went wrong. Please try again.')); // Fallback
      },
    );
  }
}
