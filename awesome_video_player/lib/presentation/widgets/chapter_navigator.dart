import 'package:flutter/material.dart';
import 'package:lumeo/core/services/chapter_service.dart';
import 'package:lumeo/core/utils/video_utils.dart';

/// Chapter navigator widget
class ChapterNavigator extends StatelessWidget {
  final List<Chapter> chapters;
  final Duration currentTime;
  final Function(Duration) onChapterSelected;

  const ChapterNavigator({
    super.key,
    required this.chapters,
    required this.currentTime,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'No chapters available',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chapters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isActive = currentTime >= chapter.startTime &&
                    currentTime <= chapter.endTime;

                return ListTile(
                  leading: chapter.thumbnailPath != null
                      ? Image.asset(
                          chapter.thumbnailPath!,
                          width: 60,
                          height: 40,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 40,
                          color: Colors.grey[800],
                          child: const Icon(Icons.play_circle_outline,
                              color: Colors.white70),
                        ),
                  title: Text(
                    chapter.title,
                    style: TextStyle(
                      color: isActive ? Colors.blue : Colors.white,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    VideoUtils.formatDuration(chapter.startTime),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: isActive
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    onChapterSelected(chapter.startTime);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

