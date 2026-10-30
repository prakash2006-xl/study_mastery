import 'dart:convert';

class DailyActivityReport {
  final String id;
  final String deviceId;
  final String date; // 'YYYY-MM-DD'
  final int totalScreenTimeSeconds;
  final int totalNotificationsCount;
  final int totalWifiBytes;
  final int totalMobileBytes;
  final Map<String, int> topApps; // packageName -> durationMs
  final DateTime generatedAt;

  DailyActivityReport({
    required this.id,
    required this.deviceId,
    required this.date,
    required this.totalScreenTimeSeconds,
    required this.totalNotificationsCount,
    required this.totalWifiBytes,
    required this.totalMobileBytes,
    required this.topApps,
    required this.generatedAt,
  });

  double get screenTimeHours => totalScreenTimeSeconds / 3600.0;

  String get formattedScreenTime {
    final hours = totalScreenTimeSeconds ~/ 3600;
    final minutes = (totalScreenTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  factory DailyActivityReport.fromMap(Map<String, dynamic> map) {
    Map<String, int> appsMap = {};
    if (map['top_apps_json'] != null && (map['top_apps_json'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['top_apps_json'] as String) as Map<String, dynamic>;
        appsMap = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      } catch (_) {}
    }

    return DailyActivityReport(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      date: map['date'] as String,
      totalScreenTimeSeconds: (map['total_screen_time_seconds'] as int?) ?? 0,
      totalNotificationsCount: (map['total_notifications_count'] as int?) ?? 0,
      totalWifiBytes: (map['total_wifi_bytes'] as int?) ?? 0,
      totalMobileBytes: (map['total_mobile_bytes'] as int?) ?? 0,
      topApps: appsMap,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(map['generated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'date': date,
      'total_screen_time_seconds': totalScreenTimeSeconds,
      'total_notifications_count': totalNotificationsCount,
      'total_wifi_bytes': totalWifiBytes,
      'total_mobile_bytes': totalMobileBytes,
      'top_apps_json': jsonEncode(topApps),
      'generated_at': generatedAt.millisecondsSinceEpoch,
    };
  }
}

