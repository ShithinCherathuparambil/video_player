import 'package:flutter/material.dart';

class AudioEqualizer extends StatefulWidget {
  final List<double> frequencies;
  final List<double> gains;
  final ValueChanged<List<double>> onGainsChanged;
  final VoidCallback? onPresetChanged;

  const AudioEqualizer({
    super.key,
    this.frequencies = const [
      60,
      170,
      310,
      600,
      1000,
      3000,
      6000,
      12000,
      14000,
      16000
    ],
    required this.gains,
    required this.onGainsChanged,
    this.onPresetChanged,
  });

  @override
  State<AudioEqualizer> createState() => _AudioEqualizerState();
}

class _AudioEqualizerState extends State<AudioEqualizer> {
  late List<double> _gains;
  String _selectedPreset = 'Flat';

  final Map<String, List<double>> _presets = {
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Pop': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Rock': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Jazz': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Classical': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Electronic': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Bass Boost': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'Treble Boost': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  };

  @override
  void initState() {
    super.initState();
    _gains = List.from(widget.gains);
    _initializePresets();
  }

  void _initializePresets() {
    _presets['Pop'] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _presets['Rock'] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _presets['Jazz'] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _presets['Classical'] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _presets['Electronic'] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _presets['Bass Boost'] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    _presets['Treble Boost'] = [
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0
    ];
  }

  void _onGainChanged(int index, double value) {
    setState(() {
      _gains[index] = value;
    });
    widget.onGainsChanged(_gains);
  }

  void _onPresetChanged(String preset) {
    setState(() {
      _selectedPreset = preset;
      _gains = List.from(_presets[preset]!);
    });
    widget.onGainsChanged(_gains);
    widget.onPresetChanged?.call();
  }

  void _resetToFlat() {
    _onPresetChanged('Flat');
  }

  String _formatFrequency(double freq) {
    if (freq >= 1000) {
      return '${(freq / 1000).toStringAsFixed(1)}k';
    }
    return freq.toInt().toString();
  }

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
                'Audio Equalizer',
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

          // Preset selector
          _buildPresetSelector(),

          const SizedBox(height: 20),

          // Equalizer sliders
          _buildEqualizerSliders(),

          const SizedBox(height: 16),

          // Reset button
          _buildResetButton(),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Presets',
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            itemBuilder: (context, index) {
              final presetName = _presets.keys.elementAt(index);
              final isSelected = presetName == _selectedPreset;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => _onPresetChanged(presetName),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      presetName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEqualizerSliders() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          widget.frequencies.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildFrequencySlider(index),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencySlider(int index) {
    return Column(
      children: [
        // Frequency label
        Text(
          _formatFrequency(widget.frequencies[index]),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),

        const SizedBox(height: 8),

        // Vertical slider
        RotatedBox(
          quarterTurns: 3,
          child: SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Theme.of(context).colorScheme.primary,
                overlayColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _gains[index],
                min: -12.0,
                max: 12.0,
                divisions: 48,
                onChanged: (value) => _onGainChanged(index, value),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Gain value
        Text(
          '${_gains[index].toStringAsFixed(1)}dB',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _resetToFlat,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text('Reset to Flat'),
      ),
    );
  }
}
