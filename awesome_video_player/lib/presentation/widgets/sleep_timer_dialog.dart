import 'package:flutter/material.dart';

/// Sleep timer dialog
class SleepTimerDialog extends StatelessWidget {
  final Function(Duration) onTimerSet;
  final VoidCallback? onCancel;

  const SleepTimerDialog({
    super.key,
    required this.onTimerSet,
    this.onCancel,
  });

  static const List<Duration> _presets = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];

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
        children: [
          const Text(
            'Sleep Timer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((duration) {
              return ElevatedButton(
                onPressed: () {
                  onTimerSet(duration);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                ),
                child: Text(_formatDuration(duration)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showCustomTimerDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Custom Time'),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                onCancel?.call();
                Navigator.pop(context);
              },
              child: const Text('Cancel Timer'),
            ),
          ],
        ],
      ),
    );
  }

  void _showCustomTimerDialog(BuildContext context) {
    final hoursController = TextEditingController();
    final minutesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Timer'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  hintText: '0',
                ),
              ),
            ),
            const Text(' : '),
            Expanded(
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutes',
                  hintText: '0',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final hours = int.tryParse(hoursController.text) ?? 0;
              final minutes = int.tryParse(minutesController.text) ?? 0;
              if (hours > 0 || minutes > 0) {
                final duration = Duration(hours: hours, minutes: minutes);
                onTimerSet(duration);
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    return '${duration.inMinutes}m';
  }
}

