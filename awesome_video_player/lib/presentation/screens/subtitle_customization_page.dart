import 'package:flutter/material.dart';
import 'package:lumeo/domain/entities/subtitle.dart';

class SubtitleCustomizationPage extends StatefulWidget {
  final SubtitleSettings initialSettings;
  final Function(SubtitleSettings) onSettingsChanged;

  const SubtitleCustomizationPage({
    super.key,
    required this.initialSettings,
    required this.onSettingsChanged,
  });

  @override
  State<SubtitleCustomizationPage> createState() =>
      _SubtitleCustomizationPageState();
}

class _SubtitleCustomizationPageState
    extends State<SubtitleCustomizationPage> {
  late SubtitleSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Subtitle Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Size'),
          Slider(
            value: _settings.fontSize,
            min: 10,
            max: 32,
            divisions: 22,
            label: _settings.fontSize.toStringAsFixed(0),
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(fontSize: value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Position'),
          Slider(
            value: _settings.position,
            min: 0.0,
            max: 0.9,
            divisions: 9,
            label: '${(_settings.position * 100).toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(position: value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Text Color'),
          _buildColorPicker(
            'Text Color',
            Color(_settings.textColor),
            (color) {
              setState(() {
                _settings = _settings.copyWith(textColor: color.value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Outline'),
          Row(
            children: [
              Expanded(
                child: Text('Outline Width: ${_settings.outlineWidth.toStringAsFixed(1)}'),
              ),
              Slider(
                value: _settings.outlineWidth,
                min: 0,
                max: 5,
                divisions: 10,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(outlineWidth: value);
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
            ],
          ),
          _buildColorPicker(
            'Outline Color',
            Color(_settings.outlineColor),
            (color) {
              setState(() {
                _settings = _settings.copyWith(outlineColor: color.value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Background'),
          _buildColorPicker(
            'Background Color',
            Color(_settings.backgroundColor),
            (color) {
              setState(() {
                _settings = _settings.copyWith(backgroundColor: color.value);
              });
              widget.onSettingsChanged(_settings);
            },
          ),
          _buildSectionTitle('Sync'),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  setState(() {
                    _settings = _settings.copyWith(
                      delayMs: _settings.delayMs - 100,
                    );
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
              Text('Delay: ${_settings.delayMs}ms'),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _settings = _settings.copyWith(
                      delayMs: _settings.delayMs + 100,
                    );
                  });
                  widget.onSettingsChanged(_settings);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    final colors = [
      Colors.white,
      Colors.yellow,
      Colors.cyan,
      Colors.green,
      Colors.red,
      Colors.blue,
      Colors.purple,
    ];

    return Wrap(
      spacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: currentColor == color ? Colors.white : Colors.grey,
                width: currentColor == color ? 3 : 1,
              ),
            ),
            child: currentColor == color
                ? const Icon(Icons.check, color: Colors.black)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

