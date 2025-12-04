import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// VLC-style playback speed selector with presets, custom input, and preference saving
class PlaybackSpeedSelector extends StatefulWidget {
  final double currentSpeed;
  final Function(double) onSpeedChanged;

  const PlaybackSpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<PlaybackSpeedSelector> createState() => _PlaybackSpeedSelectorState();
}

class _PlaybackSpeedSelectorState extends State<PlaybackSpeedSelector> {
  static const List<double> _speeds = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.25,
    1.5,
    2.0,
    4.0,
  ];

  double _customSpeed = 1.0;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSpeed();
  }

  Future<void> _loadSavedSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSpeed = prefs.getDouble('playback_speed') ?? 1.0;
    if (savedSpeed != widget.currentSpeed) {
      widget.onSpeedChanged(savedSpeed);
    }
  }

  Future<void> _saveSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', speed);
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 20.0,
      opacity: 0.3,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Playback Speed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.currentSpeed}x',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _speeds.map((speed) {
              final isSelected = (widget.currentSpeed - speed).abs() < 0.01;
              return GestureDetector(
                onTap: () {
                  widget.onSpeedChanged(speed);
                  _saveSpeed(speed);
                  MicroInteractions.hapticFeedback(
                    type: HapticFeedbackType.selectionClick,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (_showCustomInput) ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _customSpeed.clamp(0.25, 4.0),
                    min: 0.25,
                    max: 4.0,
                    divisions: 75,
                    label: '${_customSpeed.toStringAsFixed(2)}x',
                    onChanged: (value) {
                      setState(() {
                        _customSpeed = value;
                      });
                    },
                    onChangeEnd: (value) {
                      widget.onSpeedChanged(value);
                      _saveSpeed(value);
                    },
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '1.0',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      final speed = double.tryParse(value);
                      if (speed != null && speed >= 0.25 && speed <= 4.0) {
                        setState(() {
                          _customSpeed = speed;
                        });
                        widget.onSpeedChanged(speed);
                        _saveSpeed(speed);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showCustomInput = !_showCustomInput;
                if (_showCustomInput) {
                  _customSpeed = widget.currentSpeed;
                }
              });
              MicroInteractions.hapticFeedback(
                type: HapticFeedbackType.lightImpact,
              );
            },
            icon: Icon(
              _showCustomInput ? Icons.close : Icons.tune,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              _showCustomInput ? 'Hide Custom' : 'Custom Speed',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

