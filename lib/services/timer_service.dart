import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_admin_service.dart';

class TimerService extends ChangeNotifier {
  static const String _keyTimerActive = 'timer_active';
  static const String _keyTimerEndTime = 'timer_end_time';
  static const String _keyTimerDuration = 'timer_duration';

  Timer? _timer;
  bool _isActive = false;
  Duration _remainingTime = Duration.zero;
  Duration _originalDuration = Duration.zero;
  DateTime? _endTime;

  bool get isActive => _isActive;
  Duration get remainingTime => _remainingTime;
  Duration get originalDuration => _originalDuration;
  String get formattedRemainingTime => _formatDuration(_remainingTime);

  TimerService() {
    _loadTimerState();
  }

  /// Start a timer with the specified duration
  Future<bool> startTimer(Duration duration) async {
    if (_isActive) {
      await stopTimer();
    }

    // Lock screen immediately
    final bool lockSuccess = await DeviceAdminService.lockScreen();
    if (!lockSuccess) {
      return false;
    }

    _originalDuration = duration;
    _remainingTime = duration;
    _endTime = DateTime.now().add(duration);
    _isActive = true;

    await _saveTimerState();

    // Start countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });

    notifyListeners();
    return true;
  }

  /// Stop the active timer
  Future<void> stopTimer() async {
    if (!_isActive) return;

    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _remainingTime = Duration.zero;
    _endTime = null;

    await _clearTimerState();
    
    // Unlock screen
    await DeviceAdminService.unlockScreen();
    
    notifyListeners();
  }

  /// Update remaining time and check if timer is finished
  void _updateRemainingTime() {
    if (!_isActive || _endTime == null) return;

    final now = DateTime.now();
    if (now.isAfter(_endTime!)) {
      // Timer finished
      _finishTimer();
    } else {
      _remainingTime = _endTime!.difference(now);
      notifyListeners();
    }
  }

  /// Handle timer completion
  void _finishTimer() async {
    _timer?.cancel();
    _timer = null;
    _isActive = false;
    _remainingTime = Duration.zero;
    _endTime = null;

    await _clearTimerState();
    
    // Unlock screen
    await DeviceAdminService.unlockScreen();
    
    notifyListeners();
  }

  /// Load timer state from persistent storage
  Future<void> _loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isActive = prefs.getBool(_keyTimerActive) ?? false;
      
      if (_isActive) {
        final endTimeMs = prefs.getInt(_keyTimerEndTime);
        final durationMs = prefs.getInt(_keyTimerDuration);
        
        if (endTimeMs != null && durationMs != null) {
          _endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMs);
          _originalDuration = Duration(milliseconds: durationMs);
          
          final now = DateTime.now();
          if (now.isAfter(_endTime!)) {
            // Timer has already expired
            await _clearTimerState();
            _isActive = false;
            await DeviceAdminService.unlockScreen();
          } else {
            // Timer is still active
            _remainingTime = _endTime!.difference(now);
            
            // Restart the countdown timer
            _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
              _updateRemainingTime();
            });
          }
        } else {
          // Invalid state, clear it
          await _clearTimerState();
          _isActive = false;
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('Error loading timer state: $e');
      _isActive = false;
      notifyListeners();
    }
  }

  /// Save timer state to persistent storage
  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTimerActive, _isActive);
      
      if (_isActive && _endTime != null) {
        await prefs.setInt(_keyTimerEndTime, _endTime!.millisecondsSinceEpoch);
        await prefs.setInt(_keyTimerDuration, _originalDuration.inMilliseconds);
      }
    } catch (e) {
      print('Error saving timer state: $e');
    }
  }

  /// Clear timer state from persistent storage
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTimerActive);
      await prefs.remove(_keyTimerEndTime);
      await prefs.remove(_keyTimerDuration);
    } catch (e) {
      print('Error clearing timer state: $e');
    }
  }

  /// Format duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  /// Get timer progress as a value between 0.0 and 1.0
  double get progress {
    if (!_isActive || _originalDuration.inMilliseconds == 0) return 0.0;
    
    final elapsed = _originalDuration.inMilliseconds - _remainingTime.inMilliseconds;
    return elapsed / _originalDuration.inMilliseconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

