import 'package:flutter/material.dart';
import 'package:lumeo/core/services/video_effects_service.dart';

class VideoEffectsPanel extends StatefulWidget {
  final double brightness;
  final double contrast;
  final double saturation;
  final double hue;
  final double gamma;
  final String selectedFilter;
  final double rotation; // VLC-style rotation (0, 90, 180, 270)
  final bool deinterlace; // VLC-style deinterlace
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onSaturationChanged;
  final ValueChanged<double> onHueChanged;
  final ValueChanged<double> onGammaChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<double>? onRotationChanged;
  final ValueChanged<bool>? onDeinterlaceChanged;

  const VideoEffectsPanel({
    super.key,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.hue,
    required this.gamma,
    required this.selectedFilter,
    this.rotation = 0.0,
    this.deinterlace = false,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onSaturationChanged,
    required this.onHueChanged,
    required this.onGammaChanged,
    required this.onFilterChanged,
    this.onRotationChanged,
    this.onDeinterlaceChanged,
  });

  @override
  State<VideoEffectsPanel> createState() => _VideoEffectsPanelState();
}

class _VideoEffectsPanelState extends State<VideoEffectsPanel> {
  final VideoEffectsService _effectsService = VideoEffectsService();
  final List<String> _filters = [
    'None',
    'Vintage',
    'Black & White',
    'Sepia',
    'Cool',
    'Warm',
    'Dramatic',
    'Cinematic',
    'Vivid',
    'Soft',
  ];

  final Map<String, Map<String, double>> _filterPresets = {
    'None': {
      'brightness': 1.0,
      'contrast': 1.0,
      'saturation': 1.0,
      'hue': 0.0,
      'gamma': 1.0
    },
    'Vintage': {
      'brightness': 1.1,
      'contrast': 1.2,
      'saturation': 0.8,
      'hue': 15.0,
      'gamma': 1.1
    },
    'Black & White': {
      'brightness': 1.0,
      'contrast': 1.3,
      'saturation': 0.0,
      'hue': 0.0,
      'gamma': 1.0
    },
    'Sepia': {
      'brightness': 1.1,
      'contrast': 1.1,
      'saturation': 0.7,
      'hue': 30.0,
      'gamma': 1.05
    },
    'Cool': {
      'brightness': 1.0,
      'contrast': 1.1,
      'saturation': 1.2,
      'hue': -10.0,
      'gamma': 1.0
    },
    'Warm': {
      'brightness': 1.1,
      'contrast': 1.1,
      'saturation': 1.1,
      'hue': 10.0,
      'gamma': 1.05
    },
    'Dramatic': {
      'brightness': 0.9,
      'contrast': 1.4,
      'saturation': 1.3,
      'hue': 0.0,
      'gamma': 1.2
    },
    'Cinematic': {
      'brightness': 0.95,
      'contrast': 1.25,
      'saturation': 1.1,
      'hue': 0.0,
      'gamma': 1.1
    },
    'Vivid': {
      'brightness': 1.0,
      'contrast': 1.2,
      'saturation': 1.4,
      'hue': 0.0,
      'gamma': 1.0
    },
    'Soft': {
      'brightness': 1.05,
      'contrast': 0.9,
      'saturation': 0.8,
      'hue': 0.0,
      'gamma': 0.95
    },
  };

  @override
  void initState() {
    super.initState();
    _loadSavedPresets();
  }

  Future<void> _loadSavedPresets() async {
    final savedPresets = await _effectsService.getPresets();
    setState(() {
      _filterPresets.addAll(savedPresets);
    });
  }

  void _applyFilter(String filterName) {
    final preset = _filterPresets[filterName];
    if (preset != null) {
      // Update parent state
      widget.onBrightnessChanged(preset['brightness']!);
      widget.onContrastChanged(preset['contrast']!);
      widget.onSaturationChanged(preset['saturation']!);
      widget.onHueChanged(preset['hue']!);
      widget.onGammaChanged(preset['gamma']!);
      widget.onFilterChanged(filterName);

      // Save current preset
      _effectsService.saveCurrentPreset(filterName);

      // Force rebuild of this widget to update sliders and selection
      setState(() {});

      // Show visual feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied $filterName filter'),
          duration: const Duration(seconds: 1),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _saveCurrentAsPreset() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Preset'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Preset name',
            labelText: 'Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, nameController.text);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final currentValues = {
        'brightness': widget.brightness,
        'contrast': widget.contrast,
        'saturation': widget.saturation,
        'hue': widget.hue,
        'gamma': widget.gamma,
      };
      await _effectsService.savePreset(result, currentValues);
      await _loadSavedPresets();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preset "$result" saved'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _resetToDefault() {
    _applyFilter('None');
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Video Effects',
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

              // Filter presets
              _buildFilterPresets(),

              const SizedBox(height: 20),

              // Color adjustments
              _buildColorAdjustments(),

              const SizedBox(height: 20),

              // VLC-style video filters
              _buildVLCFilters(),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetToDefault,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveCurrentAsPreset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Preset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filters',
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filterName = _filters[index];
              final isSelected = filterName == widget.selectedFilter;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => _applyFilter(filterName),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            _getFilterIcon(filterName),
                            color: isSelected ? Colors.white : Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        child: Text(filterName),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getFilterIcon(String filterName) {
    switch (filterName) {
      case 'None':
        return Icons.filter_none;
      case 'Vintage':
        return Icons.camera_alt;
      case 'Black & White':
        return Icons.filter_b_and_w;
      case 'Sepia':
        return Icons.filter_vintage;
      case 'Cool':
        return Icons.ac_unit;
      case 'Warm':
        return Icons.wb_sunny;
      case 'Dramatic':
        return Icons.theater_comedy;
      case 'Cinematic':
        return Icons.movie;
      case 'Vivid':
        return Icons.color_lens;
      case 'Soft':
        return Icons.blur_on;
      default:
        return Icons.filter_none;
    }
  }

  Widget _buildColorAdjustments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Adjustments',
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildAdjustmentSlider(
          'Brightness',
          widget.brightness,
          widget.onBrightnessChanged,
          0.0,
          2.0,
          Icons.brightness_6,
        ),
        const SizedBox(height: 12),
        _buildAdjustmentSlider(
          'Contrast',
          widget.contrast,
          widget.onContrastChanged,
          0.0,
          2.0,
          Icons.contrast,
        ),
        const SizedBox(height: 12),
        _buildAdjustmentSlider(
          'Saturation',
          widget.saturation,
          widget.onSaturationChanged,
          0.0,
          2.0,
          Icons.color_lens,
        ),
        const SizedBox(height: 12),
        _buildAdjustmentSlider(
          'Hue',
          widget.hue,
          widget.onHueChanged,
          -180.0,
          180.0,
          Icons.colorize,
        ),
        const SizedBox(height: 12),
        _buildAdjustmentSlider(
          'Gamma',
          widget.gamma,
          widget.onGammaChanged,
          0.1,
          3.0,
          Icons.gradient,
        ),
      ],
    );
  }

  Widget _buildAdjustmentSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    double min,
    double max,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Spacer(),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Theme.of(context).colorScheme.primary,
            overlayColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.2),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildVLCFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VLC-Style Filters',
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // Rotation
        if (widget.onRotationChanged != null) ...[
          _buildRotationSelector(),
          const SizedBox(height: 12),
        ],

        // Deinterlace
        if (widget.onDeinterlaceChanged != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.screen_rotation, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Deinterlace',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Switch(
                value: widget.deinterlace,
                onChanged: widget.onDeinterlaceChanged,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRotationSelector() {
    final rotations = [0.0, 90.0, 180.0, 270.0];
    final rotationLabels = ['0°', '90°', '180°', '270°'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rotate_right, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            const Text(
              'Rotation',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${widget.rotation.toInt()}°',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rotations.asMap().entries.map((entry) {
            final index = entry.key;
            final rotation = entry.value;
            final isSelected = (widget.rotation - rotation).abs() < 0.1;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => widget.onRotationChanged?.call(rotation),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        rotationLabels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
