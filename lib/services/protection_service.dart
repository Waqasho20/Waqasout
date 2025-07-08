import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_admin_service.dart';

class ProtectionService extends ChangeNotifier {
  static const String _keyProtectionEnabled = 'protection_enabled';
  static const String _keyLastAdminCheck = 'last_admin_check';
  
  bool _protectionEnabled = false;
  bool _adminActive = false;
  DateTime? _lastAdminCheck;

  bool get protectionEnabled => _protectionEnabled;
  bool get adminActive => _adminActive;
  String get protectionStatus => _getProtectionStatus();

  ProtectionService() {
    _loadProtectionState();
    _startMonitoring();
  }

  /// Enable protection monitoring
  Future<bool> enableProtection() async {
    final bool adminActive = await DeviceAdminService.isAdminActive();
    
    if (!adminActive) {
      return false; // Cannot enable protection without admin privileges
    }

    _protectionEnabled = true;
    _adminActive = adminActive;
    await _saveProtectionState();
    
    notifyListeners();
    return true;
  }

  /// Disable protection monitoring
  Future<void> disableProtection() async {
    _protectionEnabled = false;
    await _saveProtectionState();
    
    notifyListeners();
  }

  /// Check current admin status
  Future<void> checkAdminStatus() async {
    final bool currentAdminStatus = await DeviceAdminService.isAdminActive();
    final bool previousAdminStatus = _adminActive;
    
    _adminActive = currentAdminStatus;
    _lastAdminCheck = DateTime.now();
    
    // If admin was revoked while protection was enabled
    if (_protectionEnabled && previousAdminStatus && !currentAdminStatus) {
      await _handleAdminRevoked();
    }
    
    await _saveProtectionState();
    notifyListeners();
  }

  /// Handle admin privileges being revoked
  Future<void> _handleAdminRevoked() async {
    print('Device admin privileges revoked - protection compromised');
    
    // Note: In a real implementation, you might want to:
    // 1. Show a persistent notification
    // 2. Try to restart the app
    // 3. Log the security event
    // 4. Attempt to re-request admin privileges
    
    // For now, we'll just disable protection
    _protectionEnabled = false;
  }

  /// Start monitoring protection status
  void _startMonitoring() {
    if (!_protectionEnabled) return;
    
    // Check admin status periodically
    Future.delayed(const Duration(seconds: 30), () {
      checkAdminStatus();
      _startMonitoring(); // Recursive call for continuous monitoring
    });
  }

  /// Load protection state from persistent storage
  Future<void> _loadProtectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _protectionEnabled = prefs.getBool(_keyProtectionEnabled) ?? false;
      
      final lastCheckMs = prefs.getInt(_keyLastAdminCheck);
      if (lastCheckMs != null) {
        _lastAdminCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckMs);
      }
      
      // Check current admin status
      await checkAdminStatus();
      
      notifyListeners();
    } catch (e) {
      print('Error loading protection state: $e');
    }
  }

  /// Save protection state to persistent storage
  Future<void> _saveProtectionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyProtectionEnabled, _protectionEnabled);
      
      if (_lastAdminCheck != null) {
        await prefs.setInt(_keyLastAdminCheck, _lastAdminCheck!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Error saving protection state: $e');
    }
  }

  /// Get human-readable protection status
  String _getProtectionStatus() {
    if (!_protectionEnabled) {
      return 'Protection disabled';
    }
    
    if (!_adminActive) {
      return 'Protection compromised - Admin privileges revoked';
    }
    
    return 'Protection active';
  }

  /// Get detailed protection information
  Map<String, dynamic> getProtectionInfo() {
    return {
      'protectionEnabled': _protectionEnabled,
      'adminActive': _adminActive,
      'status': protectionStatus,
      'lastCheck': _lastAdminCheck?.toIso8601String(),
      'canEnableProtection': !_protectionEnabled,
      'needsAdminPermission': !_adminActive,
    };
  }

  /// Force refresh of all protection status
  Future<void> refreshStatus() async {
    await checkAdminStatus();
  }

  /// Get protection recommendations
  List<String> getRecommendations() {
    final recommendations = <String>[];
    
    if (!_adminActive) {
      recommendations.add('Enable Device Administrator privileges');
    }
    
    if (!_protectionEnabled && _adminActive) {
      recommendations.add('Enable protection monitoring');
    }
    
    if (_protectionEnabled && _adminActive) {
      recommendations.add('Protection is properly configured');
    }
    
    return recommendations;
  }

  /// Attempt to recover protection (request admin again)
  Future<bool> attemptRecovery() async {
    if (_adminActive) {
      return true; // Already recovered
    }
    
    try {
      final bool success = await DeviceAdminService.requestAdminPermission();
      
      if (success) {
        _adminActive = true;
        if (!_protectionEnabled) {
          await enableProtection();
        }
        await _saveProtectionState();
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('Error attempting protection recovery: $e');
      return false;
    }
  }

  /// Check if app can be protected
  static Future<bool> canProtectApp() async {
    // Check if device admin can be requested
    try {
      final bool adminActive = await DeviceAdminService.isAdminActive();
      return adminActive; // If admin is already active, protection is possible
    } catch (e) {
      return false;
    }
  }

  /// Get time since last admin check
  Duration? getTimeSinceLastCheck() {
    if (_lastAdminCheck == null) return null;
    return DateTime.now().difference(_lastAdminCheck!);
  }

  /// Check if monitoring is healthy (recent check)
  bool get isMonitoringHealthy {
    final timeSinceCheck = getTimeSinceLastCheck();
    if (timeSinceCheck == null) return false;
    
    // Consider monitoring healthy if checked within last 2 minutes
    return timeSinceCheck.inMinutes < 2;
  }
}

