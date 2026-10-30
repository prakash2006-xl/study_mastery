class MonitoringPermission {
  final String id;
  final String permissionKey;
  final bool isGranted;
  final DateTime updatedAt;

  MonitoringPermission({
    required this.id,
    required this.permissionKey,
    required this.isGranted,
    required this.updatedAt,
  });

  factory MonitoringPermission.fromMap(Map<String, dynamic> map) {
    return MonitoringPermission(
      id: map['id'] as String,
      permissionKey: map['permission_key'] as String,
      isGranted: (map['is_granted'] as int? ?? 0) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'permission_key': permissionKey,
      'is_granted': isGranted ? 1 : 0,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  String get displayName {
    switch (permissionKey) {
      case 'usage_stats':
        return 'Usage Access (Apps & Screen)';
      case 'notification_listener':
        return 'Notification Access (Metadata only)';
      case 'battery':
        return 'Battery & Power Status';
      case 'network_stats':
        return 'Network & Data Usage';
      case 'location':
        return 'Device Location (Opt-in)';
      default:
        return permissionKey;
    }
  }

  String get description {
    switch (permissionKey) {
      case 'usage_stats':
        return 'Allows measuring app screen time, launch counts, and device unlocks.';
      case 'notification_listener':
        return 'Detects notification counts & categories. Never reads private message bodies.';
      case 'battery':
        return 'Monitors battery percentages, charging state, and power history.';
      case 'network_stats':
        return 'Measures Wi-Fi and mobile data bandwidth consumed across apps.';
      case 'location':
        return 'Optional family device location when explicitly enabled. Strictly non-covert.';
      default:
        return '';
    }
  }
}

