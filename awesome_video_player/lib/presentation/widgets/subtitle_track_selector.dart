import 'package:flutter/material.dart';

/// Subtitle track selector widget
class SubtitleTrackSelector extends StatelessWidget {
  final List<String> tracks;
  final String? selectedTrack;
  final Function(String?) onTrackSelected;

  const SubtitleTrackSelector({
    super.key,
    required this.tracks,
    this.selectedTrack,
    required this.onTrackSelected,
  });

  @override
  Widget build(BuildContext context) {
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
            'Subtitle Tracks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // None option
          ListTile(
            title: const Text(
              'None',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: selectedTrack == null
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              onTrackSelected(null);
              Navigator.pop(context);
            },
          ),
          const Divider(color: Colors.white24),
          if (tracks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No subtitle tracks available',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ...tracks.map((track) {
              final isSelected = track == selectedTrack;
              return ListTile(
                title: Text(
                  track,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  onTrackSelected(track);
                  Navigator.pop(context);
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}

