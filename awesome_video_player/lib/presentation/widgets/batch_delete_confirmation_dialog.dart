import 'package:flutter/material.dart';

class BatchDeleteConfirmationDialog extends StatelessWidget {
  final String? videoName;
  final int? videoCount;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final String? message;

  const BatchDeleteConfirmationDialog({
    super.key,
    this.videoName,
    this.videoCount,
    required this.onConfirm,
    required this.onCancel,
    this.message,
  }) : assert(videoName != null || videoCount != null,
            'Either videoName or videoCount must be provided');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                size: 32,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              videoCount != null ? 'Delete Videos' : 'Delete Video',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message ?? _getDefaultMessage(videoCount, videoName),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 8),

            // Video details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                videoCount != null
                    ? '$videoCount video${videoCount! > 1 ? 's' : ''} selected'
                    : videoName ?? 'Selected video',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Delete Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDefaultMessage(int? count, String? name) {
    if (count != null) {
      return 'Do you want to delete these $count video${count > 1 ? 's' : ''} permanently?';
    }
    if (name != null && name.isNotEmpty) {
      return 'Do you want to delete "$name" permanently?';
    }
    return 'Do you want to delete this video permanently?';
  }

  /// Show the delete confirmation dialog
  static Future<bool?> show({
    required BuildContext context,
    String? videoName,
    int? videoCount,
    String? message,
  }) {
    assert(videoName != null || videoCount != null,
        'Either videoName or videoCount must be provided');

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatchDeleteConfirmationDialog(
        videoName: videoName,
        videoCount: videoCount,
        message: message,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}
