class LocationRecord {
  final String id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  LocationRecord({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  factory LocationRecord.fromMap(Map<String, dynamic> map) {
    return LocationRecord(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

