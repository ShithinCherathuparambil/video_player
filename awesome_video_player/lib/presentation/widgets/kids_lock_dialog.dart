import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumeo/core/services/lock_screen_service.dart';

/// Kids lock PIN entry dialog
class KidsLockDialog extends StatefulWidget {
  final bool isUnlock;
  final Function()? onUnlocked;

  const KidsLockDialog({
    super.key,
    this.isUnlock = false,
    this.onUnlocked,
  });

  @override
  State<KidsLockDialog> createState() => _KidsLockDialogState();
}

class _KidsLockDialogState extends State<KidsLockDialog> {
  final LockScreenService _lockService = LockScreenService();
  final List<String> _enteredPin = [];
  final int _pinLength = 4;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              widget.isUnlock ? 'Enter PIN to Unlock' : 'Set Kids Lock PIN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // PIN display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? Colors.blue
                        : Colors.white.withOpacity(0.3),
                  ),
                );
              }),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
            const SizedBox(height: 32),
            // Number pad
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) {
          return const SizedBox.shrink(); // Empty space
        } else if (index == 10) {
          return _buildNumberButton('0');
        } else if (index == 11) {
          return IconButton(
            icon: const Icon(Icons.backspace, color: Colors.white),
            onPressed: _onBackspace,
          );
        } else {
          return _buildNumberButton('${index + 1}');
        }
      },
    );
  }

  Widget _buildNumberButton(String number) {
    return ElevatedButton(
      onPressed: () => _onNumberPressed(number),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      child: Text(
        number,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < _pinLength) {
      setState(() {
        _enteredPin.add(number);
        _errorMessage = null;
      });
      HapticFeedback.selectionClick();

      if (_enteredPin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin.removeLast();
        _errorMessage = null;
      });
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _verifyPin() async {
    if (widget.isUnlock) {
      final pin = _enteredPin.join();
      final isValid = await _lockService.verifyKidsLockPin(pin);
      
      if (isValid) {
        widget.onUnlocked?.call();
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _enteredPin.clear();
          _errorMessage = 'Incorrect PIN';
        });
      }
    } else {
      // Setting new PIN
      final pin = _enteredPin.join();
      await _lockService.setKidsLockPin(pin);
      await _lockService.setKidsLockEnabled(true);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kids lock PIN set')),
        );
      }
    }
  }
}

