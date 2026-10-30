class AppUsageEvent {
  final String id;
  final String deviceId;
  final String packageName;
  final String appName;
  final String eventType; // 'MOVE_TO_FOREGROUND', 'MOVE_TO_BACKGROUND'
  final DateTime timestamp;
  final int durationMs;

  AppUsageEvent({
    required this.id,
    required this.deviceId,
    required this.packageName,
    required this.appName,
    required this.eventType,
    required this.timestamp,
    this.durationMs = 0,
  });

  factory AppUsageEvent.fromMap(Map<String, dynamic> map) {
    return AppUsageEvent(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      packageName: map['package_name'] as String,
      appName: (map['app_name'] as String?) ?? map['package_name'] as String,
      eventType: map['event_type'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      durationMs: (map['duration_ms'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'package_name': packageName,
      'app_name': appName,
      'event_type': eventType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration_ms': durationMs,
    };
  }
}

class AppUsageSummary {
  final String packageName;
  final String appName;
  final int totalDurationMs;
  final DateTime? lastUsedTimestamp;

  AppUsageSummary({
    required this.packageName,
    required this.appName,
    required this.totalDurationMs,
    this.lastUsedTimestamp,
  });

  double get durationMinutes => totalDurationMs / (1000 * 60);
  double get durationHours => totalDurationMs / (1000 * 60 * 60);

  String get formattedDuration {
    final totalSeconds = (totalDurationMs / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  factory AppUsageSummary.fromMap(Map<String, dynamic> map) {
    return AppUsageSummary(
      packageName: map['package_name'] as String,
      appName: (map['app_name'] as String?) ?? (map['package_name'] as String),
      totalDurationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
      lastUsedTimestamp: map['last_used_timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['last_used_timestamp'] as num).toInt())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'package_name': packageName,
      'app_name': appName,
      'duration_ms': totalDurationMs,
      'last_used_timestamp': lastUsedTimestamp?.millisecondsSinceEpoch,
    };
  }
}

