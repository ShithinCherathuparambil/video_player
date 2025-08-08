import 'package:flutter/material.dart';

class AdvancedFeaturesPanel extends StatefulWidget {
  final bool hardwareAcceleration;
  final bool deinterlace;
  final bool frameDrop;
  final bool networkCaching;
  final int networkCacheSize;
  final bool audioSync;
  final double audioDelay;
  final double subtitleDelay;
  final bool showTimeRemaining;
  final bool showBuffering;
  final bool showQuality;
  final bool rememberPosition;
  final bool autoPlayNext;
  final bool shuffleEnabled;
  final String selectedQuality;
  final String selectedAudioTrack;
  final String selectedSubtitleTrack;
  final String selectedVideoTrack;

  final ValueChanged<bool> onHardwareAccelerationChanged;
  final ValueChanged<bool> onDeinterlaceChanged;
  final ValueChanged<bool> onFrameDropChanged;
  final ValueChanged<bool> onNetworkCachingChanged;
  final ValueChanged<int> onNetworkCacheSizeChanged;
  final ValueChanged<bool> onAudioSyncChanged;
  final ValueChanged<double> onAudioDelayChanged;
  final ValueChanged<double> onSubtitleDelayChanged;
  final ValueChanged<bool> onShowTimeRemainingChanged;
  final ValueChanged<bool> onShowBufferingChanged;
  final ValueChanged<bool> onShowQualityChanged;
  final ValueChanged<bool> onRememberPositionChanged;
  final ValueChanged<bool> onAutoPlayNextChanged;
  final ValueChanged<bool> onShuffleEnabledChanged;
  final ValueChanged<String> onQualityChanged;
  final ValueChanged<String> onAudioTrackChanged;
  final ValueChanged<String> onSubtitleTrackChanged;
  final ValueChanged<String> onVideoTrackChanged;

  const AdvancedFeaturesPanel({
    super.key,
    required this.hardwareAcceleration,
    required this.deinterlace,
    required this.frameDrop,
    required this.networkCaching,
    required this.networkCacheSize,
    required this.audioSync,
    required this.audioDelay,
    required this.subtitleDelay,
    required this.showTimeRemaining,
    required this.showBuffering,
    required this.showQuality,
    required this.rememberPosition,
    required this.autoPlayNext,
    required this.shuffleEnabled,
    required this.selectedQuality,
    required this.selectedAudioTrack,
    required this.selectedSubtitleTrack,
    required this.selectedVideoTrack,
    required this.onHardwareAccelerationChanged,
    required this.onDeinterlaceChanged,
    required this.onFrameDropChanged,
    required this.onNetworkCachingChanged,
    required this.onNetworkCacheSizeChanged,
    required this.onAudioSyncChanged,
    required this.onAudioDelayChanged,
    required this.onSubtitleDelayChanged,
    required this.onShowTimeRemainingChanged,
    required this.onShowBufferingChanged,
    required this.onShowQualityChanged,
    required this.onRememberPositionChanged,
    required this.onAutoPlayNextChanged,
    required this.onShuffleEnabledChanged,
    required this.onQualityChanged,
    required this.onAudioTrackChanged,
    required this.onSubtitleTrackChanged,
    required this.onVideoTrackChanged,
  });

  @override
  State<AdvancedFeaturesPanel> createState() => _AdvancedFeaturesPanelState();
}

class _AdvancedFeaturesPanelState extends State<AdvancedFeaturesPanel> {
  final List<String> _qualities = [
    'Auto',
    '1080p',
    '720p',
    '480p',
    '360p',
    '240p'
  ];
  final List<String> _audioTracks = [
    'Default',
    'English',
    'Spanish',
    'French',
    'German'
  ];
  final List<String> _subtitleTracks = [
    'None',
    'English',
    'Spanish',
    'French',
    'German'
  ];
  final List<String> _videoTracks = ['Default', 'Track 1', 'Track 2'];

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Advanced Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlSection('Performance', [
                    _buildSwitchRow(
                        'Hardware Acceleration',
                        widget.hardwareAcceleration,
                        widget.onHardwareAccelerationChanged),
                    _buildSwitchRow('Deinterlace', widget.deinterlace,
                        widget.onDeinterlaceChanged),
                    _buildSwitchRow('Frame Drop', widget.frameDrop,
                        widget.onFrameDropChanged),
                    _buildSwitchRow('Network Caching', widget.networkCaching,
                        widget.onNetworkCachingChanged),
                    if (widget.networkCaching)
                      _buildSliderRow(
                          'Cache Size (ms)', widget.networkCacheSize.toDouble(),
                          (value) {
                        widget.onNetworkCacheSizeChanged(value.toInt());
                      }, 100.0, 5000.0),
                  ]),
                  const SizedBox(height: 20),
                  _buildControlSection('Synchronization', [
                    _buildSwitchRow('Audio Sync', widget.audioSync,
                        widget.onAudioSyncChanged),
                    _buildSliderRow('Audio Delay (s)', widget.audioDelay,
                        widget.onAudioDelayChanged, -5.0, 5.0),
                    _buildSliderRow('Subtitle Delay (s)', widget.subtitleDelay,
                        widget.onSubtitleDelayChanged, -5.0, 5.0),
                  ]),
                  const SizedBox(height: 20),
                  _buildControlSection('Display', [
                    _buildSwitchRow(
                        'Show Time Remaining',
                        widget.showTimeRemaining,
                        widget.onShowTimeRemainingChanged),
                    _buildSwitchRow('Show Buffering', widget.showBuffering,
                        widget.onShowBufferingChanged),
                    _buildSwitchRow('Show Quality', widget.showQuality,
                        widget.onShowQualityChanged),
                  ]),
                  const SizedBox(height: 20),
                  _buildControlSection('Playback', [
                    _buildSwitchRow(
                        'Remember Position',
                        widget.rememberPosition,
                        widget.onRememberPositionChanged),
                    _buildSwitchRow('Auto Play Next', widget.autoPlayNext,
                        widget.onAutoPlayNextChanged),
                    _buildSwitchRow('Shuffle', widget.shuffleEnabled,
                        widget.onShuffleEnabledChanged),
                  ]),
                  const SizedBox(height: 20),
                  _buildControlSection('Quality & Tracks', [
                    _buildDropdownRow('Video Quality', widget.selectedQuality,
                        _qualities, widget.onQualityChanged),
                    _buildDropdownRow('Audio Track', widget.selectedAudioTrack,
                        _audioTracks, widget.onAudioTrackChanged),
                    _buildDropdownRow(
                        'Subtitle Track',
                        widget.selectedSubtitleTrack,
                        _subtitleTracks,
                        widget.onSubtitleTrackChanged),
                    _buildDropdownRow('Video Track', widget.selectedVideoTrack,
                        _videoTracks, widget.onVideoTrackChanged),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value,
      ValueChanged<double> onChanged, double min, double max) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(value.toStringAsFixed(2),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).colorScheme.primary,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Theme.of(context).colorScheme.primary,
              overlayColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, String value, List<String> options,
      ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          DropdownButton<String>(
            value: value,
            onChanged: (newValue) => onChanged(newValue!),
            dropdownColor: Colors.black87,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            underline: Container(),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child:
                    Text(option, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
