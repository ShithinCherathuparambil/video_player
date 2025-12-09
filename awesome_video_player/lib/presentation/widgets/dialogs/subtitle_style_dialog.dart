import 'package:flutter/material.dart';

class SubtitleStyleDialog extends StatefulWidget {
  final double initialFontSize;
  final Color initialColor;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<Color> onColorChanged;

  const SubtitleStyleDialog({
    super.key,
    required this.initialFontSize,
    required this.initialColor,
    required this.onFontSizeChanged,
    required this.onColorChanged,
  });

  @override
  State<SubtitleStyleDialog> createState() => _SubtitleStyleDialogState();
}

class _SubtitleStyleDialogState extends State<SubtitleStyleDialog> {
  late double _fontSize;
  late Color _color;

  final List<Color> _colors = [
    Colors.white,
    Colors.yellow,
    Colors.cyan,
    Colors.greenAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _fontSize = widget.initialFontSize;
    _color = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subtitle Style',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Size', style: TextStyle(color: Colors.white70)),
          Slider(
            value: _fontSize,
            min: 10.0,
            max: 40.0,
            divisions: 15,
            label: _fontSize.round().toString(),
            onChanged: (value) {
              setState(() => _fontSize = value);
              widget.onFontSizeChanged(value);
            },
          ),
          const SizedBox(height: 10),
          const Text('Color', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: _colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setState(() => _color = color);
                  widget.onColorChanged(color);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _color == color
                        ? Border.all(color: Colors.blueAccent, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
