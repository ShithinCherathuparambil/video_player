import 'dart:async';

/// Service for managing sleep timer
class SleepTimerService {
  Timer? _timer;
  Duration? _remainingTime;
  Function()? _onTimerComplete;
  Function(Duration)? _onTimerUpdate;

  /// Start sleep timer
  void startTimer(Duration duration, {Function()? onComplete, Function(Duration)? onUpdate}) {
    _onTimerComplete = onComplete;
    _onTimerUpdate = onUpdate;
    _remainingTime = duration;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime != null) {
        _remainingTime = _remainingTime! - const Duration(seconds: 1);
        
        if (_remainingTime!.isNegative || _remainingTime!.inSeconds <= 0) {
          _remainingTime = Duration.zero;
          _onTimerComplete?.call();
          cancelTimer();
        } else {
          _onTimerUpdate?.call(_remainingTime!);
        }
      }
    });
  }

  /// Cancel sleep timer
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _remainingTime = null;
  }

  /// Get remaining time
  Duration? getRemainingTime() {
    return _remainingTime;
  }

  /// Check if timer is active
  bool isActive() {
    return _timer != null && _timer!.isActive;
  }

  /// Dispose resources
  void dispose() {
    cancelTimer();
  }
}

