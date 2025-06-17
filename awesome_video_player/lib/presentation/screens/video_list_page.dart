import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import './video_player_page.dart'; // Import the VideoPlayerPage
import './settings_page.dart'; // Import the SettingsPage

class VideoListPage extends StatefulWidget {
  const VideoListPage({super.key});

  @override
  State<VideoListPage> createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage> {
  List<File> _videoFiles = [];
  bool _isLoading = true;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    PermissionStatus videoPermissionStatus;
    if (Platform.isAndroid) {
         videoPermissionStatus = await Permission.videos.request();
         if (!videoPermissionStatus.isGranted) {
           videoPermissionStatus = await Permission.storage.request();
         }
    } else if (Platform.isIOS) {
        videoPermissionStatus = await Permission.photos.request();
    } else {
        videoPermissionStatus = await Permission.storage.request();
    }

    if (videoPermissionStatus.isGranted) {
      try {
        final List<Directory> mediaDirs = [];
        if (Platform.isAndroid) {
            List<Directory>? Dirs = await getExternalStorageDirectories();
            if (Dirs != null) {
              mediaDirs.addAll(Dirs);
            }
        } else if (Platform.isIOS) {
           _message = "On iOS, use a plugin like photo_manager or image_picker to browse the Photo Library for videos.";
        }

        List<File> allVideoFiles = [];
         if (mediaDirs.isEmpty && _message.isEmpty) {
            _message = "No accessible media directories found. On Android, this might be due to scoped storage. On iOS, specific library access is needed.";
        }

        for (var dir in mediaDirs) {
          if (await dir.exists()) {
            try {
              final files = dir.listSync(recursive: true, followLinks: false);
              for (var entity in files) {
                if (entity is File) {
                  String path = entity.path.toLowerCase();
                  if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || path.endsWith('.mkv')) {
                    allVideoFiles.add(entity);
                  }
                }
              }
            } catch (e) {
              print("Error listing files in ${dir.path}: $e");
            }
          }
        }

        if (allVideoFiles.isEmpty && _message.isEmpty) {
          _message = "No video files found in the scanned directories.";
        } else if (allVideoFiles.isNotEmpty) {
          _message = '';
        }

        setState(() {
          _videoFiles = allVideoFiles;
        });

      } catch (e) {
        setState(() {
          _message = "Error fetching videos: $e";
        });
      }
    } else if (videoPermissionStatus.isDenied || videoPermissionStatus.isPermanentlyDenied) {
      _message = "Permission denied. Please enable it in app settings to see videos.";
    } else {
       _message = "Permission status: $videoPermissionStatus";
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_message.isNotEmpty && _videoFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    if (_videoFiles.isEmpty) {
      return const Center(
          child: Text(
            'No videos found.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        );
    }

    return ListView.builder(
      itemCount: _videoFiles.length,
      itemBuilder: (context, index) {
        final videoFile = _videoFiles[index];
        final fileName = videoFile.path.split('/').last;
        return ListTile(
          leading: const Icon(Icons.movie_creation_outlined, size: 40),
          title: Text(fileName),
          subtitle: Text(videoFile.path),
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
  }
}
