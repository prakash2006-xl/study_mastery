import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FamilyInsightsPlatformChannel {
  static const MethodChannel _channel =
      MethodChannel('com.example.personal_learning_os_client/family_insights');

  bool get isPlatformSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  Future<Map<String, dynamic>> getPermissionsStatus() async {
    if (!isPlatformSupported) {
      return {
        'usage_stats': false,
        'notification_listener': false,
        'battery': false,
        'network_stats': false,
        'location': false,
        'location_enabled': false,
        'monitoring_paused': false,
        'unsupported_platform': true,
      };
    }

    try {
      final result = await _channel.invokeMethod<Map>('getPermissionsStatus');
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } on PlatformException catch (e) {
      debugPrint('Error getting permissions status: $e');
    } catch (e) {
      debugPrint('Error getting permissions: $e');
    }
    return {
      'usage_stats': false,
      'notification_listener': false,
      'battery': false,
      'network_stats': false,
      'location': false,
      'location_enabled': false,
      'monitoring_paused': false,
    };
  }

  Future<bool> openPermissionSettings(String type) async {
    if (!isPlatformSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openPermissionSettings', {'type': type});
      return res ?? false;
    } catch (e) {
      debugPrint('Error opening settings for $type: $e');
      return false;
    }
  }

  Future<bool> requestLocationPermission() async {
    if (!isPlatformSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('requestLocationPermission');
      return res ?? false;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> collectAppUsage({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!isPlatformSupported) return null;
    try {
      final res = await _channel.invokeMethod<Map>('collectAppUsage', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      });
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('Error collecting app usage: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> collectBatteryStatus() async {
    if (!isPlatformSupported) return null;
    try {
      final res = await _channel.invokeMethod<Map>('collectBatteryStatus');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('Error collecting battery status: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> collectNetworkStats({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!isPlatformSupported) return null;
    try {
      final res = await _channel.invokeMethod<Map>('collectNetworkStats', {
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
      });
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('Error collecting network stats: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getNotificationEvents() async {
    if (!isPlatformSupported) return [];
    try {
      final res = await _channel.invokeListMethod('getNotificationEvents');
      if (res != null) {
        return res.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error getting notification events: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> collectLocation() async {
    if (!isPlatformSupported) return null;
    try {
      final res = await _channel.invokeMethod<Map>('collectLocation');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('Error collecting location: $e');
    }
    return null;
  }

  Future<Map<String, String>> getDeviceInfo() async {
    if (!isPlatformSupported) {
      return {
        'device_id': 'windows_desktop_demo',
        'device_model': 'Windows PC',
        'os_version': 'Microsoft Windows [Desktop]',
      };
    }
    try {
      final res = await _channel.invokeMethod<Map>('getDeviceInfo');
      if (res != null) {
        return res.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return {
      'device_id': 'android_device_unknown',
      'device_model': 'Android Device',
      'os_version': 'Android',
    };
  }

  Future<bool> scheduleBackgroundWork({int intervalMinutes = 15}) async {
    if (!isPlatformSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('scheduleBackgroundWork', {
        'intervalMinutes': intervalMinutes,
      });
      return res ?? false;
    } catch (e) {
      debugPrint('Error scheduling background work: $e');
      return false;
    }
  }

  Future<bool> cancelBackgroundWork() async {
    if (!isPlatformSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('cancelBackgroundWork');
      return res ?? false;
    } catch (e) {
      debugPrint('Error cancelling background work: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingBackgroundEvents() async {
    if (!isPlatformSupported) return [];
    try {
      final res = await _channel.invokeListMethod('getPendingBackgroundEvents');
      if (res != null) {
        return res.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error getting pending background events: $e');
    }
    return [];
  }

  Future<bool> setMonitoringPaused(bool paused) async {
    if (!isPlatformSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('setMonitoringPaused', {'paused': paused});
      return res ?? false;
    } catch (e) {
      debugPrint('Error setting monitoring paused: $e');
      return false;
    }
  }

  Future<bool> setLocationMonitoringEnabled(bool enabled) async {
    if (!isPlatformSupported) return false;
    try {
      final res = await _channel.invokeMethod<bool>('setLocationMonitoringEnabled', {'enabled': enabled});
      return res ?? false;
    } catch (e) {
      debugPrint('Error setting location monitoring enabled: $e');
      return false;
    }
  }
}

