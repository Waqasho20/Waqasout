import 'package:flutter/services.dart';

class DeviceAdminService {
  static const MethodChannel _channel = MethodChannel('com.screenlockapp.screen_lock_app/device_admin');

  /// Check if device administrator is active
  static Future<bool> isAdminActive() async {
    try {
      final bool result = await _channel.invokeMethod('isAdminActive');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check admin status: '${e.message}'.");
      return false;
    }
  }

  /// Request device administrator permission
  static Future<bool> requestAdminPermission() async {
    try {
      final bool result = await _channel.invokeMethod('requestAdminPermission');
      return result;
    } on PlatformException catch (e) {
      print("Failed to request admin permission: '${e.message}'.");
      return false;
    }
  }

  /// Remove device administrator privileges
  static Future<bool> removeAdmin() async {
    try {
      final bool result = await _channel.invokeMethod('removeAdmin');
      return result;
    } on PlatformException catch (e) {
      print("Failed to remove admin: '${e.message}'.");
      return false;
    }
  }

  /// Lock the device screen immediately
  static Future<bool> lockScreen() async {
    try {
      final bool result = await _channel.invokeMethod('lockScreen');
      return result;
    } on PlatformException catch (e) {
      print("Failed to lock screen: '${e.message}'.");
      return false;
    }
  }

  /// Unlock the device screen
  static Future<bool> unlockScreen() async {
    try {
      final bool result = await _channel.invokeMethod('unlockScreen');
      return result;
    } on PlatformException catch (e) {
      print("Failed to unlock screen: '${e.message}'.");
      return false;
    }
  }

  /// Add a new schedule
  static Future<Map<String, dynamic>?> addSchedule(int hour, int minute, int duration) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('addSchedule', {
        'hour': hour,
        'minute': minute,
        'duration': duration,
      });
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print("Failed to add schedule: '${e.message}'.");
      return null;
    }
  }

  /// Remove a schedule
  static Future<bool> removeSchedule(int scheduleId) async {
    try {
      final bool result = await _channel.invokeMethod('removeSchedule', {
        'scheduleId': scheduleId,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to remove schedule: '${e.message}'.");
      return false;
    }
  }

  /// Get all schedules
  static Future<List<Map<String, dynamic>>> getAllSchedules() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getAllSchedules');
      return result.map((schedule) => Map<String, dynamic>.from(schedule)).toList();
    } on PlatformException catch (e) {
      print("Failed to get schedules: '${e.message}'.");
      return [];
    }
  }

  /// Enable or disable a schedule
  static Future<bool> setScheduleEnabled(int scheduleId, bool enabled) async {
    try {
      final bool result = await _channel.invokeMethod('setScheduleEnabled', {
        'scheduleId': scheduleId,
        'enabled': enabled,
      });
      return result;
    } on PlatformException catch (e) {
      print("Failed to set schedule enabled: '${e.message}'.");
      return false;
    }
  }
}

