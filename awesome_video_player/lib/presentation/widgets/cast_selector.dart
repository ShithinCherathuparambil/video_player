import 'package:flutter/material.dart';
import 'package:lumeo/core/services/cast_service.dart';

/// Cast device selector widget
class CastSelector extends StatefulWidget {
  final Function(CastDevice) onDeviceSelected;

  const CastSelector({
    super.key,
    required this.onDeviceSelected,
  });

  @override
  State<CastSelector> createState() => _CastSelectorState();
}

class _CastSelectorState extends State<CastSelector> {
  final CastService _castService = CastService();
  List<CastDevice> _devices = [];
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _discoverDevices();
  }

  Future<void> _discoverDevices() async {
    setState(() {
      _isDiscovering = true;
    });

    final devices = await _castService.discoverDevices();
    
    setState(() {
      _devices = devices;
      _isDiscovering = false;
    });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cast to Device',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _discoverDevices,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isDiscovering)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_devices.isEmpty)
            const Text(
              'No devices found',
              style: TextStyle(color: Colors.white70),
            )
          else
            ..._devices.map((device) {
              return ListTile(
                leading: const Icon(Icons.cast, color: Colors.white),
                title: Text(
                  device.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  device.type,
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  widget.onDeviceSelected(device);
                  Navigator.pop(context);
                },
              );
            }).toList(),
        ],
      ),
    );
  }
}

