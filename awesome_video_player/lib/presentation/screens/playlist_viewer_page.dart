import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/blocs/playlist_bloc/playlist_bloc.dart';
import 'package:lumeo/presentation/blocs/playlist_bloc/playlist_event.dart';
import 'package:lumeo/presentation/blocs/playlist_bloc/playlist_state.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/core/utils/video_utils.dart';

class PlaylistViewerPage extends StatelessWidget {
  final List<VideoFile> videos;
  final int currentIndex;

  const PlaylistViewerPage({
    super.key,
    required this.videos,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PlaylistBloc()..add(LoadPlaylist(videos)),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Playlist'),
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<PlaylistBloc, PlaylistState>(
          builder: (context, state) {
            if (state is PlaylistLoaded) {
              return ListView.builder(
                itemCount: state.videos.length,
                itemBuilder: (context, index) {
                  final video = state.videos[index];
                  final isCurrent = index == state.currentIndex;

                  return GlassContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: video.thumbnailBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(video.thumbnailBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: video.thumbnailBytes == null
                                  ? Colors.grey[800]
                                  : null,
                            ),
                            child: video.thumbnailBytes == null
                                ? const Icon(Icons.video_library, color: Colors.white70)
                                : null,
                          ),
                          if (isCurrent)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white),
                            ),
                        ],
                      ),
                      title: Text(
                        video.name,
                        style: TextStyle(
                          color: isCurrent ? Colors.blue : Colors.white,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: video.duration != null
                          ? Text(
                              VideoUtils.formatDuration(video.duration!),
                              style: const TextStyle(color: Colors.grey),
                            )
                          : null,
                      trailing: isCurrent
                          ? const Icon(Icons.check_circle, color: Colors.blue)
                          : IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () {
                                context.read<PlaylistBloc>().add(
                                      RemoveFromPlaylist(video.path),
                                    );
                              },
                            ),
                      onTap: () {
                        context.read<PlaylistBloc>().add(SetCurrentVideo(index));
                        Navigator.pop(context, index);
                      },
                    ),
                  );
                },
              );
            }
            return const Center(
              child: Text('No videos in playlist', style: TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }
}

