class NotificationMetadata {
  final String id;
  final String deviceId;
  final String packageName;
  final String appName;
  final String category; // 'msg', 'email', 'social', 'call', 'promo', etc.
  final DateTime timestamp;

  NotificationMetadata({
    required this.id,
    required this.deviceId,
    required this.packageName,
    required this.appName,
    required this.category,
    required this.timestamp,
  });

  factory NotificationMetadata.fromMap(Map<String, dynamic> map) {
    return NotificationMetadata(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      packageName: map['package_name'] as String,
      appName: (map['app_name'] as String?) ?? (map['package_name'] as String),
      category: (map['category'] as String?) ?? 'general',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'package_name': packageName,
      'app_name': appName,
      'category': category,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

