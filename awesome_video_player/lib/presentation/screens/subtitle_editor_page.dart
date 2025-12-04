import 'package:flutter/material.dart';
import 'package:lumeo/core/services/subtitle_editor_service.dart';
import 'package:lumeo/domain/entities/subtitle.dart';
import 'package:lumeo/core/utils/video_utils.dart';

class SubtitleEditorPage extends StatefulWidget {
  final String subtitleFilePath;

  const SubtitleEditorPage({
    super.key,
    required this.subtitleFilePath,
  });

  @override
  State<SubtitleEditorPage> createState() => _SubtitleEditorPageState();
}

class _SubtitleEditorPageState extends State<SubtitleEditorPage> {
  final SubtitleEditorService _editorService = SubtitleEditorService();
  List<Subtitle> _subtitles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubtitleFile();
  }

  Future<void> _loadSubtitleFile() async {
    final loaded = await _editorService.loadSubtitleFile(widget.subtitleFilePath);
    if (loaded) {
      setState(() {
        _subtitles = _editorService.getSubtitles();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load subtitle file')),
        );
      }
    }
  }

  Future<void> _saveSubtitleFile() async {
    final saved = await _editorService.saveSubtitleFile(widget.subtitleFilePath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? 'Subtitle saved' : 'Failed to save subtitle'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Subtitle Editor'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSubtitleFile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _subtitles.length,
              itemBuilder: (context, index) {
                final subtitle = _subtitles[index];
                return ListTile(
                  title: Text(
                    subtitle.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${VideoUtils.formatDuration(subtitle.startTime)} - ${VideoUtils.formatDuration(subtitle.endTime)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white70),
                    onPressed: () => _editSubtitle(context, index, subtitle),
                  ),
                );
              },
            ),
    );
  }

  void _editSubtitle(BuildContext context, int index, Subtitle subtitle) {
    final textController = TextEditingController(text: subtitle.text);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Subtitle'),
        content: TextField(
          controller: textController,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _editorService.updateSubtitle(index, textController.text);
              setState(() {
                _subtitles = _editorService.getSubtitles();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

