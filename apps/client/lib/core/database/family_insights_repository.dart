import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';
import '../../features/family_insights/domain/models/device_activity_model.dart';
import '../../features/family_insights/domain/models/app_usage_model.dart';
import '../../features/family_insights/domain/models/screen_activity_model.dart';
import '../../features/family_insights/domain/models/notification_metadata_model.dart';
import '../../features/family_insights/domain/models/battery_model.dart';
import '../../features/family_insights/domain/models/network_usage_model.dart';
import '../../features/family_insights/domain/models/location_model.dart';
import '../../features/family_insights/domain/models/daily_activity_report_model.dart';
import '../../features/family_insights/domain/models/monitoring_permission_model.dart';

abstract class FamilyInsightsRepository {
  // Device Activity
  Future<void> saveDeviceActivity(DeviceActivity activity);
  Future<DeviceActivity?> getDeviceActivity(String deviceId);
  Future<List<DeviceActivity>> getAllDevices();

  // App Usage Events
  Future<void> saveAppUsageEvents(List<AppUsageEvent> events);
  Future<List<AppUsageEvent>> getAppUsageEvents({
    String? deviceId,
    DateTime? from,
    DateTime? to,
    String? packageName,
  });
  Future<List<AppUsageSummary>> getAppUsageSummaries({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });

  // Screen Activity
  Future<void> saveScreenActivities(List<ScreenActivity> activities);
  Future<List<ScreenActivity>> getScreenActivities({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });

  // Notification Metadata
  Future<void> saveNotificationMetadata(List<NotificationMetadata> metadata);
  Future<List<NotificationMetadata>> getNotificationMetadata({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });
  Future<Map<String, int>> getNotificationCategoryCounts({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });

  // Battery History
  Future<void> saveBatteryRecords(List<BatteryRecord> records);
  Future<List<BatteryRecord>> getBatteryHistory({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });
  Future<BatteryRecord?> getLatestBatteryRecord(String? deviceId);

  // Network Usage
  Future<void> saveNetworkUsages(List<NetworkUsage> usages);
  Future<List<NetworkUsage>> getNetworkUsage({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });

  // Location History
  Future<void> saveLocationRecords(List<LocationRecord> locations);
  Future<List<LocationRecord>> getLocationHistory({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });
  Future<LocationRecord?> getLatestLocation(String? deviceId);

  // Daily Activity Reports
  Future<void> saveDailyReport(DailyActivityReport report);
  Future<DailyActivityReport?> getDailyReport(String deviceId, String date);
  Future<List<DailyActivityReport>> getDailyReports({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  });

  // Monitoring Permissions
  Future<void> updatePermission(String key, bool isGranted);
  Future<Map<String, bool>> getPermissions();

  // Data Management
  Future<void> clearAllData();
}

class SqliteFamilyInsightsRepository implements FamilyInsightsRepository {
  final Database _db;

  SqliteFamilyInsightsRepository(this._db);

  @override
  Future<void> saveDeviceActivity(DeviceActivity activity) async {
    await _db.insert(
      'device_activity',
      activity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<DeviceActivity?> getDeviceActivity(String deviceId) async {
    final results = await _db.query(
      'device_activity',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DeviceActivity.fromMap(results.first);
  }

  @override
  Future<List<DeviceActivity>> getAllDevices() async {
    final results = await _db.query('device_activity', orderBy: 'last_sync_timestamp DESC');
    return results.map((m) => DeviceActivity.fromMap(m)).toList();
  }

  @override
  Future<void> saveAppUsageEvents(List<AppUsageEvent> events) async {
    if (events.isEmpty) return;
    final batch = _db.batch();
    for (final event in events) {
      batch.insert(
        'app_usage_events',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<AppUsageEvent>> getAppUsageEvents({
    String? deviceId,
    DateTime? from,
    DateTime? to,
    String? packageName,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (packageName != null) {
      whereClauses.add('package_name = ?');
      whereArgs.add(packageName);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _db.query(
      'app_usage_events',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((m) => AppUsageEvent.fromMap(m)).toList();
  }

  @override
  Future<List<AppUsageSummary>> getAppUsageSummaries({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final results = await _db.rawQuery('''
      SELECT 
        package_name,
        COALESCE(MAX(app_name), package_name) as app_name,
        SUM(duration_ms) as total_duration_ms,
        MAX(timestamp) as last_used_timestamp
      FROM app_usage_events
      $whereSql
      GROUP BY package_name
      ORDER BY total_duration_ms DESC
    ''', whereArgs);

    return results.map((m) {
      return AppUsageSummary(
        packageName: m['package_name'] as String,
        appName: (m['app_name'] as String?) ?? (m['package_name'] as String),
        totalDurationMs: (m['total_duration_ms'] as num?)?.toInt() ?? 0,
        lastUsedTimestamp: m['last_used_timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch((m['last_used_timestamp'] as num).toInt())
            : null,
      );
    }).toList();
  }

  @override
  Future<void> saveScreenActivities(List<ScreenActivity> activities) async {
    if (activities.isEmpty) return;
    final batch = _db.batch();
    for (final act in activities) {
      batch.insert(
        'screen_activity',
        act.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<ScreenActivity>> getScreenActivities({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _db.query(
      'screen_activity',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((m) => ScreenActivity.fromMap(m)).toList();
  }

  @override
  Future<void> saveNotificationMetadata(List<NotificationMetadata> metadata) async {
    if (metadata.isEmpty) return;
    final batch = _db.batch();
    for (final item in metadata) {
      batch.insert(
        'notification_metadata',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<NotificationMetadata>> getNotificationMetadata({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _db.query(
      'notification_metadata',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((m) => NotificationMetadata.fromMap(m)).toList();
  }

  @override
  Future<Map<String, int>> getNotificationCategoryCounts({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final whereSql = whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final results = await _db.rawQuery('''
      SELECT category, COUNT(*) as count
      FROM notification_metadata
      $whereSql
      GROUP BY category
      ORDER BY count DESC
    ''', whereArgs);

    final counts = <String, int>{};
    for (final row in results) {
      final category = (row['category'] as String?) ?? 'general';
      final count = (row['count'] as num?)?.toInt() ?? 0;
      counts[category] = count;
    }
    return counts;
  }

  @override
  Future<void> saveBatteryRecords(List<BatteryRecord> records) async {
    if (records.isEmpty) return;
    final batch = _db.batch();
    for (final r in records) {
      batch.insert(
        'battery_history',
        r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<BatteryRecord>> getBatteryHistory({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _db.query(
      'battery_history',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((m) => BatteryRecord.fromMap(m)).toList();
  }

  @override
  Future<BatteryRecord?> getLatestBatteryRecord(String? deviceId) async {
    final results = await _db.query(
      'battery_history',
      where: deviceId != null ? 'device_id = ?' : null,
      whereArgs: deviceId != null ? [deviceId] : null,
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return BatteryRecord.fromMap(results.first);
  }

  @override
  Future<void> saveNetworkUsages(List<NetworkUsage> usages) async {
    if (usages.isEmpty) return;
    final batch = _db.batch();
    for (final u in usages) {
      batch.insert(
        'network_usage',
        u.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<NetworkUsage>> getNetworkUsage({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _db.query(
      'network_usage',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((m) => NetworkUsage.fromMap(m)).toList();
  }

  @override
  Future<void> saveLocationRecords(List<LocationRecord> locations) async {
    if (locations.isEmpty) return;
    final batch = _db.batch();
    for (final loc in locations) {
      batch.insert(
        'location_history',
        loc.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<LocationRecord>> getLocationHistory({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }
    if (from != null) {
      whereClauses.add('timestamp >= ?');
      whereArgs.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      whereClauses.add('timestamp <= ?');
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final results = await _db.query(
      'location_history',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return results.map((m) => LocationRecord.fromMap(m)).toList();
  }

  @override
  Future<LocationRecord?> getLatestLocation(String? deviceId) async {
    final results = await _db.query(
      'location_history',
      where: deviceId != null ? 'device_id = ?' : null,
      whereArgs: deviceId != null ? [deviceId] : null,
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return LocationRecord.fromMap(results.first);
  }

  @override
  Future<void> saveDailyReport(DailyActivityReport report) async {
    await _db.insert(
      'daily_activity_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<DailyActivityReport?> getDailyReport(String deviceId, String date) async {
    final results = await _db.query(
      'daily_activity_reports',
      where: 'device_id = ? AND date = ?',
      whereArgs: [deviceId, date],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DailyActivityReport.fromMap(results.first);
  }

  @override
  Future<List<DailyActivityReport>> getDailyReports({
    String? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('device_id = ?');
      whereArgs.add(deviceId);
    }

    final results = await _db.query(
      'daily_activity_reports',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );

    return results.map((m) => DailyActivityReport.fromMap(m)).toList();
  }

  @override
  Future<void> updatePermission(String key, bool isGranted) async {
    await _db.insert(
      'monitoring_permissions',
      {
        'id': key,
        'permission_key': key,
        'is_granted': isGranted ? 1 : 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Map<String, bool>> getPermissions() async {
    final results = await _db.query('monitoring_permissions');
    final map = <String, bool>{};
    for (final row in results) {
      map[row['permission_key'] as String] = (row['is_granted'] as int) == 1;
    }
    return map;
  }

  @override
  Future<void> clearAllData() async {
    await _db.delete('device_activity');
    await _db.delete('app_usage_events');
    await _db.delete('screen_activity');
    await _db.delete('notification_metadata');
    await _db.delete('battery_history');
    await _db.delete('network_usage');
    await _db.delete('location_history');
    await _db.delete('daily_activity_reports');
  }
}

final familyInsightsRepositoryProvider = Provider<FamilyInsightsRepository?>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => SqliteFamilyInsightsRepository(db),
    loading: () => null,
    error: (_, __) => null,
  );
});

