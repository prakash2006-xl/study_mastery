class DeviceActivity {
  final String id;
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final DateTime lastSyncTimestamp;
  final bool isMonitoringActive;

  DeviceActivity({
    required this.id,
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.lastSyncTimestamp,
    this.isMonitoringActive = true,
  });

  factory DeviceActivity.fromMap(Map<String, dynamic> map) {
    return DeviceActivity(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      deviceModel: (map['device_model'] as String?) ?? 'Android Device',
      osVersion: (map['os_version'] as String?) ?? 'Unknown OS',
      lastSyncTimestamp: DateTime.fromMillisecondsSinceEpoch(map['last_sync_timestamp'] as int),
      isMonitoringActive: (map['is_monitoring_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'device_model': deviceModel,
      'os_version': osVersion,
      'last_sync_timestamp': lastSyncTimestamp.millisecondsSinceEpoch,
      'is_monitoring_active': isMonitoringActive ? 1 : 0,
    };
  }

  DeviceActivity copyWith({
    String? id,
    String? deviceId,
    String? deviceModel,
    String? osVersion,
    DateTime? lastSyncTimestamp,
    bool? isMonitoringActive,
  }) {
    return DeviceActivity(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      isMonitoringActive: isMonitoringActive ?? this.isMonitoringActive,
    );
  }
}

