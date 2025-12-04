import 'package:flutter/material.dart';
import 'package:lumeo/core/services/network_stream_service.dart';

/// Widget for selecting network stream quality
class NetworkStreamQualitySelector extends StatelessWidget {
  final List<StreamQuality> qualities;
  final StreamQuality? selectedQuality;
  final Function(StreamQuality) onQualitySelected;
  final bool isNetworkStream;

  const NetworkStreamQualitySelector({
    super.key,
    required this.qualities,
    this.selectedQuality,
    required this.onQualitySelected,
    this.isNetworkStream = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isNetworkStream || qualities.isEmpty) {
      return const SizedBox.shrink();
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
            'Stream Quality',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (qualities.isEmpty)
            const Text(
              'No quality options available',
              style: TextStyle(color: Colors.white70),
            )
          else
            ...qualities.map((quality) {
              final isSelected = selectedQuality?.url == quality.url;
              return ListTile(
                title: Text(
                  quality.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: quality.bitrate != null
                    ? Text(
                        '${(quality.bitrate! / 1000).toStringAsFixed(0)} kbps',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.white54,
                        ),
                      )
                    : null,
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  onQualitySelected(quality);
                  Navigator.pop(context);
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}

