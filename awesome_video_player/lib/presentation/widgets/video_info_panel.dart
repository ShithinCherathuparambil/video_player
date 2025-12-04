import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lumeo/domain/entities/video_file.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';
import 'package:flutter/services.dart';

/// Video info panel with smooth expand/collapse animation
/// Displays metadata, file information, and statistics
class VideoInfoPanel extends StatefulWidget {
  final VideoFile video;
  final double? fps;
  final double? bitrate;
  final String? codec;
  final String? resolution;
  final Duration? bufferDuration;

  const VideoInfoPanel({
    super.key,
    required this.video,
    this.fps,
    this.bitrate,
    this.codec,
    this.resolution,
    this.bufferDuration,
  });

  @override
  State<VideoInfoPanel> createState() => _VideoInfoPanelState();
}

class _VideoInfoPanelState extends State<VideoInfoPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    MicroInteractions.hapticFeedback(
      type: HapticFeedbackType.lightImpact,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with expand/collapse button
          GestureDetector(
            onTap: _toggleExpansion,
            child: GlassContainer(
              blur: 20.0,
              opacity: 0.3,
              borderRadius: BorderRadius.circular(20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Video Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Icon(
                      Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _expandAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  child: GlassContainer(
                    blur: 25.0,
                    opacity: 0.4,
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.all(20),
                    child: _buildInfoContent(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Information Section
        _buildSection(
          context,
          title: 'Basic Information',
          icon: Icons.video_library,
          children: [
            _buildInfoRow(
              context,
              label: 'Name',
              value: widget.video.name,
            ),
            if (widget.video.duration != null)
              _buildInfoRow(
                context,
                label: 'Duration',
                value: _formatDuration(widget.video.duration!),
              ),
            if (widget.video.fileSize != null)
              _buildInfoRow(
                context,
                label: 'File Size',
                value: _formatFileSize(widget.video.fileSize!),
              ),
            if (widget.video.dateAdded != null)
              _buildInfoRow(
                context,
                label: 'Date Added',
                value: DateFormat('MMM dd, yyyy HH:mm').format(widget.video.dateAdded!),
              ),
            _buildInfoRow(
              context,
              label: 'Status',
              value: widget.video.status.toString().split('.').last,
            ),
            _buildInfoRow(
              context,
              label: 'Favorite',
              value: widget.video.isFavorite ? 'Yes' : 'No',
              icon: widget.video.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Playback Information Section
        if (widget.video.lastPlayedPosition != null ||
            widget.video.lastPlayedAt != null)
          _buildSection(
            context,
            title: 'Playback Information',
            icon: Icons.play_circle_outline,
            children: [
              if (widget.video.lastPlayedPosition != null)
                _buildInfoRow(
                  context,
                  label: 'Last Position',
                  value: _formatDuration(widget.video.lastPlayedPosition!),
                ),
              if (widget.video.lastPlayedAt != null)
                _buildInfoRow(
                  context,
                  label: 'Last Played',
                  value: DateFormat('MMM dd, yyyy HH:mm')
                      .format(widget.video.lastPlayedAt!),
                ),
            ],
          ),

        // Statistics Section
        if (widget.fps != null ||
            widget.bitrate != null ||
            widget.codec != null ||
            widget.resolution != null)
          ...[
            const SizedBox(height: 20),
            _buildSection(
              context,
              title: 'Statistics',
              icon: Icons.analytics,
              children: [
                if (widget.fps != null)
                  _buildInfoRow(
                    context,
                    label: 'FPS',
                    value: '${widget.fps!.toStringAsFixed(1)}',
                  ),
                if (widget.bitrate != null)
                  _buildInfoRow(
                    context,
                    label: 'Bitrate',
                    value: '${widget.bitrate!.toStringAsFixed(2)} Mbps',
                  ),
                if (widget.codec != null && widget.codec!.isNotEmpty)
                  _buildInfoRow(
                    context,
                    label: 'Codec',
                    value: widget.codec!,
                  ),
                if (widget.resolution != null && widget.resolution!.isNotEmpty)
                  _buildInfoRow(
                    context,
                    label: 'Resolution',
                    value: widget.resolution!,
                  ),
                if (widget.bufferDuration != null)
                  _buildInfoRow(
                    context,
                    label: 'Buffer',
                    value: _formatDuration(widget.bufferDuration!),
                  ),
              ],
            ),
          ],

        const SizedBox(height: 20),

        // File Path Section
        _buildSection(
          context,
          title: 'File Path',
          icon: Icons.folder,
          children: [
            _buildInfoRow(
              context,
              label: 'Path',
              value: widget.video.path,
              isPath: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    IconData? icon,
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: isPath
                  ? () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Path copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      MicroInteractions.hapticFeedback(
                        type: HapticFeedbackType.selectionClick,
                      );
                    }
                  : null,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                maxLines: isPath ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

