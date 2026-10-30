class ScreenActivity {
  final String id;
  final String deviceId;
  final String eventType; // 'SCREEN_INTERACTIVE', 'SCREEN_NON_INTERACTIVE', 'KEYGUARD_SHOWN', 'KEYGUARD_HIDDEN'
  final DateTime timestamp;

  ScreenActivity({
    required this.id,
    required this.deviceId,
    required this.eventType,
    required this.timestamp,
  });

  factory ScreenActivity.fromMap(Map<String, dynamic> map) {
    return ScreenActivity(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      eventType: map['event_type'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'event_type': eventType,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  String get readableTitle {
    switch (eventType) {
      case 'SCREEN_INTERACTIVE':
        return 'Screen Turned On / Interactive';
      case 'SCREEN_NON_INTERACTIVE':
        return 'Screen Turned Off';
      case 'KEYGUARD_SHOWN':
        return 'Device Locked';
      case 'KEYGUARD_HIDDEN':
        return 'Device Unlocked';
      default:
        return eventType;
    }
  }
}

