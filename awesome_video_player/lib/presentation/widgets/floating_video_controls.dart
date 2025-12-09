import 'package:flutter/material.dart';
import 'package:lumeo/presentation/widgets/advanced_features_panel.dart';

class FloatingVideoControls extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final VoidCallback? onTogglePlayPause;
  final bool isPlaying;
  final bool showControls;
  final VoidCallback onOpenEqualizer;
  final VoidCallback onOpenVideoEffects;
  final bool hasVideoEffects;
  final VoidCallback onOpenAdvancedFeatures;
  final VoidCallback? onOpenFitModeSelector;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onToggleStatistics;
  final VoidCallback onOpenPlaylist;
  final VoidCallback onOpenChapters;
  final VoidCallback? onBookmarksTap; // New callback
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
  final bool backgroundPlayEnabled;
  final String loopMode;
  final List<String> availableAudioTracks;
  final List<String> availableSubtitleTracks;
  final bool ambientModeEnabled;
  final ValueChanged<bool> onAmbientModeChanged;
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
  final ValueChanged<bool> onBackgroundPlayEnabledChanged;
  final ValueChanged<String> onLoopModeChanged;

  const FloatingVideoControls({
    super.key,
    required this.position,
    required this.duration,
    this.onTogglePlayPause,
    required this.isPlaying,
    required this.showControls,
    required this.onOpenEqualizer,
    required this.onOpenVideoEffects,
    required this.hasVideoEffects,
    required this.onOpenAdvancedFeatures,
    this.onOpenFitModeSelector,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onToggleStatistics,
    required this.onOpenPlaylist,
    required this.onOpenChapters,
    this.onBookmarksTap,
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
    required this.backgroundPlayEnabled,
    required this.loopMode,
    this.availableAudioTracks = const [],
    this.availableSubtitleTracks = const [],
    required this.ambientModeEnabled,
    required this.onAmbientModeChanged,
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
    required this.onBackgroundPlayEnabledChanged,
    required this.onLoopModeChanged,
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
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top floating controls - comprehensive 3-dot menu
                      _buildTopFloatingControls(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Left: Back & Title
          _buildGlassButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
            backgroundColor: Colors.transparent, // Cleaner look
          ),
          const SizedBox(width: 12),
          Expanded(
            child: const Text(
              'Video Title', // TODO: Pass title
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Right: Settings & Tracks
          // HW/SW Decoder Toggle (Placeholder logic for now, standard MX feature)
          _buildGlassButton(
            icon: widget.hardwareAcceleration ? Icons.memory : Icons.create,
            onPressed: () {
              // Toggle HW/SW
              widget
                  .onHardwareAccelerationChanged(!widget.hardwareAcceleration);
            },
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),

          // Audio Track
          _buildGlassButton(
            icon: Icons.audiotrack,
            onPressed: () {
              _showAudioTrackSelection();
            },
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),

          // Subtitle Track
          _buildGlassButton(
            icon: Icons.subtitles,
            onPressed: () {
              _showSubtitleTrackSelection();
            },
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),

          // Bookmarks
          _buildGlassButton(
            icon: Icons.bookmark_border,
            onPressed: widget.onBookmarksTap ?? () {},
            backgroundColor: Colors.transparent,
          ),
          const SizedBox(width: 8),

          // Settings (Kebab)
          _buildGlassButton(
            icon: Icons.more_vert,
            onPressed: () {
              // Show advanced menu or old quick menu
              setState(() {
                _showAdvancedMenu = !_showAdvancedMenu;
              });
              if (_showAdvancedMenu) {
                _showAdvancedFeaturesPanel();
              }
            },
            backgroundColor: Colors.transparent,
          ),
        ],
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
        backgroundPlayEnabled: widget.backgroundPlayEnabled,
        loopMode: widget.loopMode,
        onBackgroundPlayEnabledChanged: widget.onBackgroundPlayEnabledChanged,
        onLoopModeChanged: widget.onLoopModeChanged,
        ambientModeEnabled: widget.ambientModeEnabled,
        onAmbientModeChanged: widget.onAmbientModeChanged,
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

  void _showAudioTrackSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Select Audio Track',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.availableAudioTracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No audio tracks available',
                    style: TextStyle(color: Colors.white70)),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.availableAudioTracks.map((track) {
                      final isSelected = widget.selectedAudioTrack == track;
                      return ListTile(
                        leading: isSelected
                            ? const Icon(Icons.check, color: Colors.blueAccent)
                            : const SizedBox(width: 24),
                        title: Text(
                          track,
                          style: TextStyle(
                            color:
                                isSelected ? Colors.blueAccent : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          widget.onAudioTrackChanged(track);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSubtitleTrackSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                'Select Subtitle Track',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (widget.availableSubtitleTracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No subtitle tracks available',
                    style: TextStyle(color: Colors.white70)),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.availableSubtitleTracks.map((track) {
                      final isSelected = widget.selectedSubtitleTrack == track;
                      return ListTile(
                        leading: isSelected
                            ? const Icon(Icons.check, color: Colors.blueAccent)
                            : const SizedBox(width: 24),
                        title: Text(
                          track,
                          style: TextStyle(
                            color:
                                isSelected ? Colors.blueAccent : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          widget.onSubtitleTrackChanged(track);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
