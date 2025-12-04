import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

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
    this.availableAudioTracks = const [],
    this.availableSubtitleTracks = const [],
  });

  @override
  State<MxPlayerControls> createState() => _MxPlayerControlsState();
}

class _MxPlayerControlsState extends State<MxPlayerControls> {
  bool _showVolumeControl = false;
  bool _showBrightnessControl = false;
  bool _showSpeedControl = false;
  bool _showLanguageControl = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
                        _showVolumeControl = false;
                        _showBrightnessControl = false;
                        _showSpeedControl = false;
                        _showLanguageControl = false;
        });
      }
    });
  }

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
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Seekbar with time indicators
            _buildSeekbar(),
            
            const SizedBox(height: 8),
            
            // Main control buttons row - make scrollable to prevent overflow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Play/Pause
                    _buildControlButton(
                      icon: widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      onPressed: () {
                        widget.onTogglePlayPause();
                        MicroInteractions.hapticFeedback(type: HapticFeedbackType.mediumImpact);
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Volume control
                    _buildControlButton(
                      icon: widget.volume > 0 ? Icons.volume_up : Icons.volume_off,
                      onPressed: () {
                        setState(() {
                          _showVolumeControl = !_showVolumeControl;
                          _showBrightnessControl = false;
                          _showSpeedControl = false;
                          _showLanguageControl = false;
                        });
                        _resetHideTimer();
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Brightness control
                    _buildControlButton(
                      icon: Icons.brightness_6,
                      onPressed: () {
                        setState(() {
                          _showBrightnessControl = !_showBrightnessControl;
                          _showVolumeControl = false;
                          _showSpeedControl = false;
                          _showLanguageControl = false;
                        });
                        _resetHideTimer();
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Playback speed
                    _buildControlButton(
                      icon: Icons.speed,
                      label: '${widget.playbackSpeed}x',
                      onPressed: () {
                        setState(() {
                          _showSpeedControl = !_showSpeedControl;
                          _showVolumeControl = false;
                          _showBrightnessControl = false;
                          _showLanguageControl = false;
                        });
                        _resetHideTimer();
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Subtitle toggle
                    _buildControlButton(
                      icon: widget.subtitlesEnabled ? Icons.subtitles : Icons.subtitles_off,
                      onPressed: () {
                        widget.onSubtitlesToggled(!widget.subtitlesEnabled);
                        MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Language/Audio track
                    _buildControlButton(
                      icon: Icons.language,
                      onPressed: () {
                        setState(() {
                          _showLanguageControl = !_showLanguageControl;
                          _showVolumeControl = false;
                          _showBrightnessControl = false;
                          _showSpeedControl = false;
                        });
                        _resetHideTimer();
                      },
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // More options (3-dot menu)
                    _buildControlButton(
                      icon: Icons.more_vert,
                      onPressed: () {
                        _showMoreOptionsMenu(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Volume control panel
            if (_showVolumeControl) _buildVolumeControl(),
            
            // Brightness control panel
            if (_showBrightnessControl) _buildBrightnessControl(),
            
            // Speed control panel
            if (_showSpeedControl) _buildSpeedControl(),
            
            // Language control panel
            if (_showLanguageControl) _buildLanguageControl(),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekbar() {
    final progress = widget.duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / widget.duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Time indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(widget.position),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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
          const SizedBox(height: 8),
          // Seekbar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (widget.duration.inMilliseconds * value).round(),
                );
                widget.onSeek(newPosition);
                MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: label != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              : Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildVolumeControl() {
    final effectiveVolume = (widget.volume * widget.audioBoost).clamp(0.0, 2.0);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Volume',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(effectiveVolume * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Volume slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: widget.volume.clamp(0.0, 1.0),
              onChanged: (value) {
                widget.onVolumeChanged(value);
                MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Audio boost slider (up to 200%)
          Row(
            children: [
              const Icon(Icons.volume_up, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Audio Boost',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${(widget.audioBoost * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.orange,
              inactiveTrackColor: Colors.orange.withOpacity(0.3),
              thumbColor: Colors.orange,
              overlayColor: Colors.orange.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: widget.audioBoost.clamp(1.0, 2.0),
              min: 1.0,
              max: 2.0,
              divisions: 20,
              label: '${(widget.audioBoost * 100).toInt()}%',
              onChanged: (value) {
                widget.onAudioBoostChanged(value);
                MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrightnessControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Brightness',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(widget.brightness * 100).toInt()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.yellow,
              inactiveTrackColor: Colors.yellow.withOpacity(0.3),
              thumbColor: Colors.yellow,
              overlayColor: Colors.yellow.withOpacity(0.2),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: widget.brightness.clamp(0.0, 1.0),
              onChanged: (value) {
                widget.onBrightnessChanged(value);
                MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0, 4.0];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Playback Speed',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: speeds.map((speed) {
              final isSelected = (widget.playbackSpeed - speed).abs() < 0.01;
              return ChoiceChip(
                label: Text('${speed}x'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    widget.onPlaybackSpeedChanged(speed);
                    MicroInteractions.hapticFeedback(type: HapticFeedbackType.lightImpact);
                  }
                },
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audio & Subtitles',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Audio track selector
          if (widget.availableAudioTracks.isNotEmpty) ...[
            const Text(
              'Audio Track',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: widget.selectedAudioTrack,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.9),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              iconEnabledColor: Colors.white,
              items: widget.availableAudioTracks.map((track) {
                return DropdownMenuItem<String>(
                  value: track,
                  child: Text(track),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  widget.onAudioTrackChanged(value);
                  MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          // Subtitle track selector
          if (widget.availableSubtitleTracks.isNotEmpty) ...[
            const Text(
              'Subtitle Track',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: widget.selectedSubtitleTrack,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.9),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              iconEnabledColor: Colors.white,
              items: widget.availableSubtitleTracks.map((track) {
                return DropdownMenuItem<String>(
                  value: track,
                  child: Text(track),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  widget.onSubtitleTrackChanged(value);
                  MicroInteractions.hapticFeedback(type: HapticFeedbackType.selectionClick);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showMoreOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.subtitles, color: Colors.white),
              title: const Text('Subtitle Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenSubtitleSettings?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.white),
              title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenSleepTimer?.call();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

