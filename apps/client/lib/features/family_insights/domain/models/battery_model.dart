class BatteryRecord {
  final String id;
  final String deviceId;
  final int batteryLevel; // 0 - 100
  final String chargingStatus; // 'CHARGING', 'DISCHARGING', 'FULL', 'NOT_CHARGING'
  final String pluggedType; // 'AC', 'USB', 'WIRELESS', 'NONE'
  final DateTime timestamp;

  BatteryRecord({
    required this.id,
    required this.deviceId,
    required this.batteryLevel,
    required this.chargingStatus,
    required this.pluggedType,
    required this.timestamp,
  });

  factory BatteryRecord.fromMap(Map<String, dynamic> map) {
    return BatteryRecord(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      batteryLevel: (map['battery_level'] as int?) ?? 0,
      chargingStatus: (map['charging_status'] as String?) ?? 'UNKNOWN',
      pluggedType: (map['plugged_type'] as String?) ?? 'NONE',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'battery_level': batteryLevel,
      'charging_status': chargingStatus,
      'plugged_type': pluggedType,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  bool get isCharging => chargingStatus == 'CHARGING' || pluggedType != 'NONE';
}

