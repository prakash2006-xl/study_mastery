class NetworkUsage {
  final String id;
  final String deviceId;
  final String networkType; // 'WIFI', 'MOBILE'
  final String? packageName;
  final int rxBytes; // Download
  final int txBytes; // Upload
  final DateTime startTime;
  final DateTime endTime;
  final DateTime timestamp;

  NetworkUsage({
    required this.id,
    required this.deviceId,
    required this.networkType,
    this.packageName,
    required this.rxBytes,
    required this.txBytes,
    required this.startTime,
    required this.endTime,
    required this.timestamp,
  });

  int get totalBytes => rxBytes + txBytes;

  double get rxMegabytes => rxBytes / (1024 * 1024);
  double get txMegabytes => txBytes / (1024 * 1024);
  double get totalMegabytes => totalBytes / (1024 * 1024);

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  factory NetworkUsage.fromMap(Map<String, dynamic> map) {
    return NetworkUsage(
      id: map['id'] as String,
      deviceId: map['device_id'] as String,
      networkType: map['network_type'] as String,
      packageName: map['package_name'] as String?,
      rxBytes: (map['rx_bytes'] as int?) ?? 0,
      txBytes: (map['tx_bytes'] as int?) ?? 0,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['start_time'] as int),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['end_time'] as int),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'network_type': networkType,
      'package_name': packageName,
      'rx_bytes': rxBytes,
      'tx_bytes': txBytes,
      'start_time': startTime.millisecondsSinceEpoch,
      'end_time': endTime.millisecondsSinceEpoch,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}

