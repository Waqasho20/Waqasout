import 'package:flutter/foundation.dart';
import '../models/schedule.dart';
import 'device_admin_service.dart';

class ScheduleService extends ChangeNotifier {
  List<Schedule> _schedules = [];
  
  List<Schedule> get schedules => List.unmodifiable(_schedules);
  
  /// Get all active schedules
  List<Schedule> get activeSchedules => 
      _schedules.where((schedule) => schedule.enabled).toList();

  /// Initialize and load schedules from native side
  Future<void> initialize() async {
    await loadSchedules();
  }

  /// Load schedules from native Android code
  Future<void> loadSchedules() async {
    try {
      final List<Map<String, dynamic>> scheduleData = 
          await DeviceAdminService.getAllSchedules();
      
      _schedules = scheduleData.map((data) => Schedule.fromMap(data)).toList();
      _schedules.sort((a, b) {
        // Sort by time (hour, then minute)
        if (a.hour != b.hour) {
          return a.hour.compareTo(b.hour);
        }
        return a.minute.compareTo(b.minute);
      });
      
      notifyListeners();
    } catch (e) {
      print('Error loading schedules: $e');
    }
  }

  /// Add a new schedule
  Future<bool> addSchedule({
    required int hour,
    required int minute,
    required int durationMinutes,
    Set<int>? daysOfWeek,
  }) async {
    try {
      final Map<String, dynamic>? result = await DeviceAdminService.addSchedule(
        hour,
        minute,
        durationMinutes,
      );
      
      if (result != null) {
        final newSchedule = Schedule.fromMap(result);
        _schedules.add(newSchedule);
        _sortSchedules();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding schedule: $e');
      return false;
    }
  }

  /// Remove a schedule
  Future<bool> removeSchedule(int scheduleId) async {
    try {
      final bool success = await DeviceAdminService.removeSchedule(scheduleId);
      
      if (success) {
        _schedules.removeWhere((schedule) => schedule.id == scheduleId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing schedule: $e');
      return false;
    }
  }

  /// Enable or disable a schedule
  Future<bool> setScheduleEnabled(int scheduleId, bool enabled) async {
    try {
      final bool success = await DeviceAdminService.setScheduleEnabled(
        scheduleId,
        enabled,
      );
      
      if (success) {
        final index = _schedules.indexWhere((schedule) => schedule.id == scheduleId);
        if (index != -1) {
          _schedules[index] = _schedules[index].copyWith(enabled: enabled);
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error setting schedule enabled: $e');
      return false;
    }
  }

  /// Get schedule by ID
  Schedule? getSchedule(int scheduleId) {
    try {
      return _schedules.firstWhere((schedule) => schedule.id == scheduleId);
    } catch (e) {
      return null;
    }
  }

  /// Get next upcoming schedule
  Schedule? getNextSchedule() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute; // Current time in minutes
    final currentDayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    
    Schedule? nextSchedule;
    int minTimeDiff = 24 * 60 * 7; // One week in minutes
    
    for (final schedule in activeSchedules) {
      if (!schedule.daysOfWeek.contains(currentDayOfWeek)) {
        continue; // Schedule not active today
      }
      
      final scheduleTime = schedule.hour * 60 + schedule.minute;
      
      if (scheduleTime > currentTime) {
        // Schedule is later today
        final timeDiff = scheduleTime - currentTime;
        if (timeDiff < minTimeDiff) {
          minTimeDiff = timeDiff;
          nextSchedule = schedule;
        }
      }
    }
    
    // If no schedule found for today, look for tomorrow and beyond
    if (nextSchedule == null) {
      for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
        final checkDay = ((currentDayOfWeek + dayOffset - 1) % 7) + 1;
        
        for (final schedule in activeSchedules) {
          if (schedule.daysOfWeek.contains(checkDay)) {
            final timeDiff = (dayOffset * 24 * 60) + 
                           (schedule.hour * 60 + schedule.minute) - currentTime;
            if (timeDiff < minTimeDiff) {
              minTimeDiff = timeDiff;
              nextSchedule = schedule;
            }
          }
        }
        
        if (nextSchedule != null) break;
      }
    }
    
    return nextSchedule;
  }

  /// Get next schedule time as DateTime
  DateTime? getNextScheduleTime() {
    final nextSchedule = getNextSchedule();
    if (nextSchedule == null) return null;
    
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final scheduleTime = nextSchedule.hour * 60 + nextSchedule.minute;
    
    DateTime nextTime = DateTime(
      now.year,
      now.month,
      now.day,
      nextSchedule.hour,
      nextSchedule.minute,
    );
    
    // If schedule time has passed today, move to next valid day
    if (scheduleTime <= currentTime || 
        !nextSchedule.daysOfWeek.contains(now.weekday)) {
      
      for (int dayOffset = 1; dayOffset <= 7; dayOffset++) {
        nextTime = nextTime.add(Duration(days: 1));
        if (nextSchedule.daysOfWeek.contains(nextTime.weekday)) {
          break;
        }
      }
    }
    
    return nextTime;
  }

  /// Get formatted string for next schedule
  String getNextScheduleString() {
    final nextSchedule = getNextSchedule();
    final nextTime = getNextScheduleTime();
    
    if (nextSchedule == null || nextTime == null) {
      return 'No upcoming schedules';
    }
    
    final now = DateTime.now();
    final difference = nextTime.difference(now);
    
    String timeUntil;
    if (difference.inDays > 0) {
      timeUntil = 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      timeUntil = 'in ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      timeUntil = 'in ${difference.inMinutes}m';
    }
    
    return '${nextSchedule.timeString} ($timeUntil)';
  }

  /// Sort schedules by time
  void _sortSchedules() {
    _schedules.sort((a, b) {
      if (a.hour != b.hour) {
        return a.hour.compareTo(b.hour);
      }
      return a.minute.compareTo(b.minute);
    });
  }

  /// Clear all schedules
  Future<bool> clearAllSchedules() async {
    try {
      bool allSuccess = true;
      
      for (final schedule in List.from(_schedules)) {
        final success = await removeSchedule(schedule.id);
        if (!success) allSuccess = false;
      }
      
      return allSuccess;
    } catch (e) {
      print('Error clearing all schedules: $e');
      return false;
    }
  }

  /// Get schedule statistics
  Map<String, dynamic> getScheduleStats() {
    return {
      'total': _schedules.length,
      'active': activeSchedules.length,
      'inactive': _schedules.length - activeSchedules.length,
      'nextSchedule': getNextScheduleString(),
    };
  }
}

