import 'package:flutter/material.dart';

class SleepTimerDialog extends StatelessWidget {
  const SleepTimerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Sleep Timer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildOption(context, 'Off', null),
          _buildOption(context, '10 minutes', const Duration(minutes: 10)),
          _buildOption(context, '30 minutes', const Duration(minutes: 30)),
          _buildOption(context, '1 hour', const Duration(hours: 1)),
          _buildOption(context, 'End of video',
              const Duration(days: 365)), // Special value logic
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, Duration? duration) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context, duration);
      },
    );
  }
}
