import 'package:flutter/material.dart';

/// MX Player-style comprehensive video controls
class MxPlayerControls extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final double volume; // 0.0 to 1.0
  final double audioBoost; // 1.0 to 2.0 (100% to 200%)
  final double brightness; // 0.0 to 1.0
  final double playbackSpeed; // 0.25 to 4.0
  final bool subtitlesEnabled;
  final String selectedAudioTrack;
  final String selectedSubtitleTrack;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onAudioBoostChanged;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onPlaybackSpeedChanged;
  final ValueChanged<bool> onSubtitlesToggled;
  final ValueChanged<String> onAudioTrackChanged;
  final ValueChanged<String> onSubtitleTrackChanged;
  final VoidCallback? onOpenSubtitleSettings;
  final VoidCallback? onOpenSleepTimer;
  final VoidCallback? onLockToggle;
  final VoidCallback? onToggleFit;
  final List<String> availableAudioTracks;
  final List<String> availableSubtitleTracks;

  const MxPlayerControls({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.volume,
    required this.audioBoost,
    required this.brightness,
    required this.playbackSpeed,
    required this.subtitlesEnabled,
    required this.selectedAudioTrack,
    required this.selectedSubtitleTrack,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onVolumeChanged,
    required this.onAudioBoostChanged,
    required this.onBrightnessChanged,
    required this.onPlaybackSpeedChanged,
    required this.onSubtitlesToggled,
    required this.onAudioTrackChanged,
    required this.onSubtitleTrackChanged,
    this.onOpenSubtitleSettings,
    this.onOpenSleepTimer,
    this.onLockToggle,
    this.onToggleFit,
    this.availableAudioTracks = const [],
    this.availableSubtitleTracks = const [],
  });

  @override
  State<MxPlayerControls> createState() => _MxPlayerControlsState();
}

class _MxPlayerControlsState extends State<MxPlayerControls> {
  // We don't need internal state for volume/brightness since they are gesture-based now.
  // We might want callbacks for lock/unlock if this widget handles it, but currently
  // the parent handles lock state. The parent needs to pass down 'onLockToggle' and 'isLocked'.
  // However, the prompt says "controls" are hidden when locked, EXCEPT a lock button.
  // But typically the *unlock* button is part of a different overlay if everything else is hidden.
  // For this widget, we assume it's the "Active Controls" bar.

  // Implementation note: The parent `VideoPlayerPage` toggles `_showControls`.
  // If we want a LOCK button here, it will lock the interface.

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16, top: 10),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Seek Bar with Time
            Row(
              children: [
                Text(
                  _formatDuration(widget.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:
                          Colors.blueAccent, // MX Player blue style
                      inactiveTrackColor: Colors.white30,
                      thumbColor: Colors.blueAccent,
                      overlayColor: Colors.blueAccent.withOpacity(0.2),
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: widget.duration.inMilliseconds > 0
                          ? (widget.position.inMilliseconds /
                                  widget.duration.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (value) {
                        final newPos = widget.duration * value;
                        widget.onSeek(newPos);
                      },
                    ),
                  ),
                ),
                Text(
                  _formatDuration(widget.duration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Row 2: Transport Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lock Button (Triggers lock on parent)
                // Note: The parent passes a callback for this. We need to add it to the widget.
                // For now, we'll use a placeholder or reuse a callback if available.
                // The current `MxPlayerControls` definition doesn't have `onLock`.
                // We will add it to the Widget definition in a moment, but for this step
                // we'll comment it out or put a temporary icon until we update the signature.
                IconButton(
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  onPressed: () {
                    // We need to bubble this up.
                    // Since we can't change the signature in this tool call easily without
                    // changing the header too, we'll assume we can use `onTogglePlayPause`
                    // or we need to do a multi-replace to update the class definition too.
                    // I will update the class definition in this same tool call.
                    widget.onLockToggle?.call();
                  },
                ),

                // Transport Controls Centered
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.skip_previous, color: Colors.white),
                      onPressed: () {
                        // Check availability or remove if not needed
                        // Typically "Previous" in playlist
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () => widget.onSeek(
                          widget.position - const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.black26,
                      ),
                      child: IconButton(
                        icon: Icon(
                            widget.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white),
                        iconSize: 32,
                        onPressed: widget.onTogglePlayPause,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => widget.onSeek(
                          widget.position + const Duration(seconds: 10)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      onPressed: () {
                        // Next functionality
                      },
                    ),
                  ],
                ),

                // Playback Speed
                IconButton(
                  icon: const Icon(Icons.speed, color: Colors.white),
                  onPressed: () {
                    _showPlaybackSpeedDialog(context);
                  },
                ),

                // Fit Screen (Aspect Ratio)
                IconButton(
                  icon: const Icon(Icons.aspect_ratio, color: Colors.white),
                  onPressed: () {
                    // Toggle fit mode
                    widget.onToggleFit?.call();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaybackSpeedDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  'Playback Speed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0]
                        .map((speed) {
                      final isSelected = widget.playbackSpeed == speed;
                      return ListTile(
                        leading: isSelected
                            ? const Icon(Icons.check, color: Colors.blueAccent)
                            : const SizedBox(width: 24),
                        title: Text(
                          '${speed}x',
                          style: TextStyle(
                            color:
                                isSelected ? Colors.blueAccent : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          widget.onPlaybackSpeedChanged(speed);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
