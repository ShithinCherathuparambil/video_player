import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/services/video_player_service.dart' as vps;
import 'package:lumeo/core/services/format_detection_service.dart';
import 'package:lumeo/presentation/widgets/glassmorphism/glass_container.dart';
import 'package:lumeo/core/utils/micro_interactions.dart';

/// Decoder selection UI with hardware/software toggle, decoder info, and automatic fallback
class DecoderSelector extends StatefulWidget {
  final vps.VideoPlayerService playerService;
  final FormatDetectionResult? formatResult;
  final Function(vps.DecoderType)? onDecoderChanged;

  const DecoderSelector({
    super.key,
    required this.playerService,
    this.formatResult,
    this.onDecoderChanged,
  });

  @override
  State<DecoderSelector> createState() => _DecoderSelectorState();
}

class _DecoderSelectorState extends State<DecoderSelector> {
  bool _isSwitching = false;
  String? _decoderInfo;
  bool _autoFallbackEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadDecoderInfo();
  }

  void _loadDecoderInfo() {
    final decoder = widget.playerService.currentDecoder;
    final playerType = widget.playerService.currentPlayerType;
    
    setState(() {
      _decoderInfo = _getDecoderInfo(decoder, playerType);
    });
  }

  String _getDecoderInfo(vps.DecoderType decoder, vps.PlayerType playerType) {
    final decoderName = decoder == vps.DecoderType.hardware
        ? 'Hardware'
        : 'Software';
    final playerName = playerType == vps.PlayerType.betterPlayer
        ? 'Better Player'
        : playerType == vps.PlayerType.vlc
            ? 'VLC Player'
            : 'Video Player';
    
    return '$decoderName ($playerName)';
  }

  Future<void> _switchDecoder() async {
    if (_isSwitching) return;

    setState(() {
      _isSwitching = true;
    });

    try {
      MicroInteractions.hapticFeedback(
        type: HapticFeedbackType.mediumImpact,
      );

      await widget.playerService.switchDecoder();
      
      _loadDecoderInfo();
      
      if (widget.onDecoderChanged != null) {
        widget.onDecoderChanged!(widget.playerService.currentDecoder);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Switched to ${widget.playerService.currentDecoder == vps.DecoderType.hardware ? "Hardware" : "Software"} decoder',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch decoder: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red.withOpacity(0.8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDecoder = widget.playerService.currentDecoder;
    final supportsHardware = widget.formatResult?.supportsHardwareDecoding ?? true;

    return GlassContainer(
      blur: 20.0,
      opacity: 0.3,
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.settings_applications,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Decoder Selection',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
              if (_isSwitching)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Current Decoder Info
          _buildInfoCard(
            context,
            'Current Decoder',
            _decoderInfo ?? 'Unknown',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 16),

          // Format Info
          if (widget.formatResult != null)
            _buildInfoCard(
              context,
              'Format',
              widget.formatResult!.format.toUpperCase(),
              icon: Icons.video_file,
            ),
          if (widget.formatResult != null) const SizedBox(height: 16),

          // Hardware Decoding Support
          _buildInfoCard(
            context,
            'Hardware Decoding',
            supportsHardware ? 'Supported' : 'Not Supported',
            icon: supportsHardware ? Icons.check_circle : Icons.cancel,
            color: supportsHardware ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 20),

          // Decoder Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decoder Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentDecoder == vps.DecoderType.hardware
                          ? 'Hardware (GPU accelerated)'
                          : 'Software (CPU based)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Switch(
                  value: currentDecoder == vps.DecoderType.hardware,
                  onChanged: supportsHardware && !_isSwitching
                      ? (value) {
                          if (value != (currentDecoder == vps.DecoderType.hardware)) {
                            _switchDecoder();
                          }
                        }
                      : null,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          if (!supportsHardware) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This format does not support hardware decoding',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Automatic Fallback
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automatic Fallback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Switch decoder automatically if playback fails',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Switch(
                value: _autoFallbackEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoFallbackEnabled = value;
                  });
                  MicroInteractions.hapticFeedback(
                    type: HapticFeedbackType.selectionClick,
                  );
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Decoder Info Section
          ExpansionTile(
            title: Text(
              'Decoder Information',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Hardware Decoder',
                      'Uses GPU for video decoding. Faster and more power-efficient, but may not support all formats.',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Software Decoder',
                      'Uses CPU for video decoding. More compatible with all formats, but may be slower and use more battery.',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      'Automatic Fallback',
                      'If hardware decoding fails, the player will automatically switch to software decoding.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color ?? Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

