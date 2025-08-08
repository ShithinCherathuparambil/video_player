import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:lumeo/presentation/widgets/advanced_features_panel.dart';

class FloatingVideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isPlaying;
  final bool showControls;
  final VoidCallback onOpenEqualizer;
  final VoidCallback onOpenVideoEffects;
  final bool hasVideoEffects;
  final VoidCallback onOpenAdvancedFeatures;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onToggleStatistics;
  final VoidCallback onOpenPlaylist;
  final VoidCallback onOpenChapters;
  final ValueChanged<double> onPlaybackSpeedChanged;
  final double playbackSpeed;
  final bool showStatistics;
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

  const FloatingVideoControls({
    super.key,
    required this.controller,
    required this.isPlaying,
    required this.showControls,
    required this.onOpenEqualizer,
    required this.onOpenVideoEffects,
    required this.hasVideoEffects,
    required this.onOpenAdvancedFeatures,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onToggleStatistics,
    required this.onOpenPlaylist,
    required this.onOpenChapters,
    required this.onPlaybackSpeedChanged,
    required this.playbackSpeed,
    required this.showStatistics,
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
  State<FloatingVideoControls> createState() => _FloatingVideoControlsState();
}

class _FloatingVideoControlsState extends State<FloatingVideoControls>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showQuickControls = false;
  bool _showAdvancedMenu = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    if (widget.showControls) {
      _fadeController.forward();
      _scaleController.forward();
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showControls != oldWidget.showControls) {
      if (widget.showControls) {
        _fadeController.forward();
        _scaleController.forward();
        _slideController.forward();
      } else {
        _fadeController.reverse();
        _scaleController.reverse();
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showControls) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation:
          Listenable.merge([_fadeAnimation, _scaleAnimation, _slideAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top floating controls - comprehensive 3-dot menu
                      _buildTopFloatingControls(),

                      const Spacer(),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopFloatingControls() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Spacer(),

          // Comprehensive 3-dot menu
          _buildGlassButton(
            icon: _showQuickControls ? Icons.close : Icons.more_vert,
            onPressed: () {
              setState(() {
                _showQuickControls = !_showQuickControls;
                if (!_showQuickControls) {
                  _showAdvancedMenu = false;
                }
              });
            },
          ),

          if (_showQuickControls) ...[
            const SizedBox(width: 8),
            // Use Flexible to prevent overflow
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildGlassButton(
                      icon: Icons.graphic_eq,
                      onPressed: widget.onOpenEqualizer,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: widget.hasVideoEffects
                          ? Icons.filter_alt
                          : Icons.filter,
                      onPressed: widget.onOpenVideoEffects,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.speed,
                      onPressed: _showPlaybackSpeedOptions,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.settings,
                      onPressed: () {
                        setState(() {
                          _showAdvancedMenu = !_showAdvancedMenu;
                        });
                        if (_showAdvancedMenu) {
                          _showAdvancedFeaturesPanel();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.skip_next,
                      onPressed: widget.onSeekForward,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.skip_previous,
                      onPressed: widget.onSeekBackward,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: widget.showStatistics
                          ? Icons.analytics
                          : Icons.analytics_outlined,
                      onPressed: widget.onToggleStatistics,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.playlist_play,
                      onPressed: widget.onOpenPlaylist,
                    ),
                    const SizedBox(width: 8),
                    _buildGlassButton(
                      icon: Icons.bookmark,
                      onPressed: widget.onOpenChapters,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPlaybackSpeedOptions() {
    final speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

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
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Playback Speed',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: speeds.length,
              itemBuilder: (context, index) {
                final speed = speeds[index];
                final isSelected = speed == widget.playbackSpeed;

                return InkWell(
                  onTap: () {
                    widget.onPlaybackSpeedChanged(speed);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${speed}x',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAdvancedFeaturesPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AdvancedFeaturesPanel(
        hardwareAcceleration: widget.hardwareAcceleration,
        deinterlace: widget.deinterlace,
        frameDrop: widget.frameDrop,
        networkCaching: widget.networkCaching,
        networkCacheSize: widget.networkCacheSize,
        audioSync: widget.audioSync,
        audioDelay: widget.audioDelay,
        subtitleDelay: widget.subtitleDelay,
        showTimeRemaining: widget.showTimeRemaining,
        showBuffering: widget.showBuffering,
        showQuality: widget.showQuality,
        rememberPosition: widget.rememberPosition,
        autoPlayNext: widget.autoPlayNext,
        shuffleEnabled: widget.shuffleEnabled,
        selectedQuality: widget.selectedQuality,
        selectedAudioTrack: widget.selectedAudioTrack,
        selectedSubtitleTrack: widget.selectedSubtitleTrack,
        selectedVideoTrack: widget.selectedVideoTrack,
        onHardwareAccelerationChanged: widget.onHardwareAccelerationChanged,
        onDeinterlaceChanged: widget.onDeinterlaceChanged,
        onFrameDropChanged: widget.onFrameDropChanged,
        onNetworkCachingChanged: widget.onNetworkCachingChanged,
        onNetworkCacheSizeChanged: widget.onNetworkCacheSizeChanged,
        onAudioSyncChanged: widget.onAudioSyncChanged,
        onAudioDelayChanged: widget.onAudioDelayChanged,
        onSubtitleDelayChanged: widget.onSubtitleDelayChanged,
        onShowTimeRemainingChanged: widget.onShowTimeRemainingChanged,
        onShowBufferingChanged: widget.onShowBufferingChanged,
        onShowQualityChanged: widget.onShowQualityChanged,
        onRememberPositionChanged: widget.onRememberPositionChanged,
        onAutoPlayNextChanged: widget.onAutoPlayNextChanged,
        onShuffleEnabledChanged: widget.onShuffleEnabledChanged,
        onQualityChanged: widget.onQualityChanged,
        onAudioTrackChanged: widget.onAudioTrackChanged,
        onSubtitleTrackChanged: widget.onSubtitleTrackChanged,
        onVideoTrackChanged: widget.onVideoTrackChanged,
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
