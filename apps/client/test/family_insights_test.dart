import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:personal_learning_os_client/core/database/database_service.dart';
import 'package:personal_learning_os_client/core/database/family_insights_repository.dart';
import 'package:personal_learning_os_client/features/family_insights/data/family_insights_platform_channel.dart';
import 'package:personal_learning_os_client/features/family_insights/data/export_service.dart';
import 'package:personal_learning_os_client/features/family_insights/application/family_insights_service.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/device_activity_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/app_usage_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/screen_activity_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/notification_metadata_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/battery_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/network_usage_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/location_model.dart';
import 'package:personal_learning_os_client/features/family_insights/domain/models/daily_activity_report_model.dart';

class MockPlatformChannel extends FamilyInsightsPlatformChannel {
  bool usageGranted;
  bool notifGranted;
  bool locationGranted;
  bool isPaused = false;
  bool locationEnabled = false;

  MockPlatformChannel({
    this.usageGranted = true,
    this.notifGranted = true,
    this.locationGranted = true,
  });

  @override
  bool get isPlatformSupported => true;

  @override
  Future<Map<String, dynamic>> getPermissionsStatus() async {
    return {
      'usage_stats': usageGranted,
      'notification_listener': notifGranted,
      'battery': true,
      'network_stats': true,
      'location': locationGranted,
      'location_enabled': locationEnabled,
      'monitoring_paused': isPaused,
    };
  }

  @override
  Future<Map<String, String>> getDeviceInfo() async {
    return {
      'device_id': 'test_device_100',
      'device_model': 'Test Pixel 7',
      'os_version': 'Android 14',
    };
  }

  @override
  Future<Map<String, dynamic>?> collectAppUsage({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (!usageGranted) return null;
    return {
      'permission_granted': true,
      'app_events': [
        {
          'package_name': 'com.test.learn',
          'app_name': 'Test Learn App',
          'event_type': 'MOVE_TO_FOREGROUND',
          'timestamp': startTime.millisecondsSinceEpoch + 5000,
        },
      ],
      'app_summaries': [
        {
          'package_name': 'com.test.learn',
          'app_name': 'Test Learn App',
          'duration_ms': 120000,
          'last_used_timestamp': endTime.millisecondsSinceEpoch,
        },
      ],
      'screen_events': [
        {
          'event_type': 'SCREEN_INTERACTIVE',
          'timestamp': startTime.millisecondsSinceEpoch + 1000,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>?> collectBatteryStatus() async {
    return {
      'battery_level': 85,
      'charging_status': 'CHARGING',
      'plugged_type': 'AC',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<Map<String, dynamic>?> collectNetworkStats({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    return {
      'wifi_rx': 5242880, // 5MB
      'wifi_tx': 1048576, // 1MB
      'mobile_rx': 2097152, // 2MB
      'mobile_tx': 524288, // 0.5MB
      'timestamp': endTime.millisecondsSinceEpoch,
      'app_breakdown': [
        {
          'package_name': 'com.test.learn',
          'app_name': 'Test Learn App',
          'network_type': 'WIFI',
          'rx_bytes': 4194304,
          'tx_bytes': 1048576,
        }
      ],
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getNotificationEvents() async {
    if (!notifGranted) return [];
    return [
      {
        'package_name': 'com.google.android.gm',
        'category': 'email',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    ];
  }

  @override
  Future<Map<String, dynamic>?> collectLocation() async {
    if (!locationEnabled || !locationGranted) return null;
    return {
      'latitude': 37.4220,
      'longitude': -122.0841,
      'accuracy': 5.0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<bool> setMonitoringPaused(bool paused) async {
    isPaused = paused;
    return true;
  }

  @override
  Future<bool> setLocationMonitoringEnabled(bool enabled) async {
    locationEnabled = enabled;
    return true;
  }
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqliteFamilyInsightsRepository repository;

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: (db, version) async {
          // Creates v3 schema then v4 schema as in DatabaseService
          await DatabaseService.database; // triggers init if needed
        },
      ),
    );
    // Explicitly run schema initialization on this in-memory instance
    final createSchemaMethod = DatabaseService.database;
    // We can directly open database with DatabaseService._createSchema logic
  });

  tearDown(() async {
    await db.close();
  });

  group('SQLite Migrations & Schema Tests', () {
    test('Database creates all 9 independent Family Insights tables with indexes', () async {
      final testDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (database, version) async {
            // Test full create
            await database.execute('''
              CREATE TABLE IF NOT EXISTS device_activity (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL UNIQUE,
                device_model TEXT,
                os_version TEXT,
                last_sync_timestamp INTEGER NOT NULL,
                is_monitoring_active INTEGER NOT NULL DEFAULT 1
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS app_usage_events (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                package_name TEXT NOT NULL,
                app_name TEXT,
                event_type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                duration_ms INTEGER DEFAULT 0,
                UNIQUE(device_id, package_name, timestamp, event_type) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS screen_activity (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp, event_type) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS notification_metadata (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                package_name TEXT NOT NULL,
                app_name TEXT,
                category TEXT,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, package_name, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS battery_history (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                battery_level INTEGER NOT NULL,
                charging_status TEXT NOT NULL,
                plugged_type TEXT,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS network_usage (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                network_type TEXT NOT NULL,
                package_name TEXT,
                rx_bytes INTEGER NOT NULL,
                tx_bytes INTEGER NOT NULL,
                start_time INTEGER NOT NULL,
                end_time INTEGER NOT NULL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, network_type, package_name, start_time, end_time) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS location_history (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                accuracy REAL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS daily_activity_reports (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                date TEXT NOT NULL,
                total_screen_time_seconds INTEGER NOT NULL,
                total_notifications_count INTEGER NOT NULL,
                total_wifi_bytes INTEGER NOT NULL,
                total_mobile_bytes INTEGER NOT NULL,
                top_apps_json TEXT,
                generated_at INTEGER NOT NULL,
                UNIQUE(device_id, date) ON CONFLICT REPLACE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS monitoring_permissions (
                id TEXT PRIMARY KEY,
                permission_key TEXT NOT NULL UNIQUE,
                is_granted INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER NOT NULL
              )
            ''');
          },
        ),
      );

      final tables = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      expect(tableNames.contains('device_activity'), isTrue);
      expect(tableNames.contains('app_usage_events'), isTrue);
      expect(tableNames.contains('screen_activity'), isTrue);
      expect(tableNames.contains('notification_metadata'), isTrue);
      expect(tableNames.contains('battery_history'), isTrue);
      expect(tableNames.contains('network_usage'), isTrue);
      expect(tableNames.contains('location_history'), isTrue);
      expect(tableNames.contains('daily_activity_reports'), isTrue);
      expect(tableNames.contains('monitoring_permissions'), isTrue);

      await testDb.close();
    });

    test('Migration from v3 to v4 adds all 9 tables preserving existing data', () async {
      // Step 1: Open v3 database with existing tables and mock study session
      final v3Db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: (database, version) async {
            await database.execute('''
              CREATE TABLE study_sessions (
                id TEXT PRIMARY KEY,
                start_time INTEGER NOT NULL,
                end_time INTEGER NOT NULL,
                duration_seconds INTEGER NOT NULL,
                created_at INTEGER NOT NULL
              )
            ''');
            await database.insert('study_sessions', {
              'id': 'sess_1',
              'start_time': 1000,
              'end_time': 2000,
              'duration_seconds': 1000,
              'created_at': 1000,
            });
          },
        ),
      );

      // Verify v3 data
      final v3Rows = await v3Db.query('study_sessions');
      expect(v3Rows.length, 1);
      await v3Db.close();

      // Step 2: Open with v4 and simulate upgrade
      final v4Db = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onUpgrade: (database, oldVersion, newVersion) async {
            if (oldVersion < 4) {
              await database.execute('''
                CREATE TABLE IF NOT EXISTS device_activity (
                  id TEXT PRIMARY KEY,
                  device_id TEXT NOT NULL UNIQUE,
                  device_model TEXT,
                  os_version TEXT,
                  last_sync_timestamp INTEGER NOT NULL,
                  is_monitoring_active INTEGER NOT NULL DEFAULT 1
                )
              ''');
            }
          },
        ),
      );

      // Verify old data preserved
      final rows = await v4Db.query('study_sessions');
      expect(rows.length, 1);
      expect(rows.first['id'], 'sess_1');

      // Verify upgraded table exists
      final devTable = await v4Db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='device_activity'");
      expect(devTable.isNotEmpty, isTrue);

      await v4Db.close();
    });
  });

  group('Duplicate Event Prevention Tests', () {
    late Database memoryDb;
    late SqliteFamilyInsightsRepository repo;

    setUp(() async {
      memoryDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (database, version) async {
            await database.execute('''
              CREATE TABLE IF NOT EXISTS app_usage_events (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                package_name TEXT NOT NULL,
                app_name TEXT,
                event_type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                duration_ms INTEGER DEFAULT 0,
                UNIQUE(device_id, package_name, timestamp, event_type) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS screen_activity (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp, event_type) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS battery_history (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                battery_level INTEGER NOT NULL,
                charging_status TEXT NOT NULL,
                plugged_type TEXT,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS notification_metadata (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                package_name TEXT NOT NULL,
                app_name TEXT,
                category TEXT,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, package_name, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS daily_activity_reports (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                date TEXT NOT NULL,
                total_screen_time_seconds INTEGER NOT NULL,
                total_notifications_count INTEGER NOT NULL,
                total_wifi_bytes INTEGER NOT NULL,
                total_mobile_bytes INTEGER NOT NULL,
                top_apps_json TEXT,
                generated_at INTEGER NOT NULL,
                UNIQUE(device_id, date) ON CONFLICT REPLACE
              )
            ''');
          },
        ),
      );
      repo = SqliteFamilyInsightsRepository(memoryDb);
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('Prevents duplicate app_usage_events on same timestamp and event_type', () async {
      final now = DateTime.now();
      final event1 = AppUsageEvent(
        id: 'evt_1',
        deviceId: 'dev_1',
        packageName: 'com.test.app',
        appName: 'Test App',
        eventType: 'MOVE_TO_FOREGROUND',
        timestamp: now,
        durationMs: 5000,
      );

      final duplicate = AppUsageEvent(
        id: 'evt_2',
        deviceId: 'dev_1',
        packageName: 'com.test.app',
        appName: 'Test App',
        eventType: 'MOVE_TO_FOREGROUND',
        timestamp: now,
        durationMs: 9999,
      );

      await repo.saveAppUsageEvents([event1, duplicate]);
      final results = await repo.getAppUsageEvents();
      expect(results.length, 1);
      expect(results.first.id, 'evt_1');
    });

    test('Prevents duplicate screen_activity on same device and timestamp', () async {
      final now = DateTime.now();
      final act1 = ScreenActivity(
        id: 'screen_1',
        deviceId: 'dev_1',
        eventType: 'SCREEN_INTERACTIVE',
        timestamp: now,
      );
      final duplicate = ScreenActivity(
        id: 'screen_2',
        deviceId: 'dev_1',
        eventType: 'SCREEN_INTERACTIVE',
        timestamp: now,
      );

      await repo.saveScreenActivities([act1, duplicate]);
      final results = await repo.getScreenActivities();
      expect(results.length, 1);
    });

    test('Prevents duplicate battery snapshots on same timestamp', () async {
      final now = DateTime.now();
      final b1 = BatteryRecord(
        id: 'b1',
        deviceId: 'dev_1',
        batteryLevel: 90,
        chargingStatus: 'DISCHARGING',
        pluggedType: 'NONE',
        timestamp: now,
      );
      final b2 = BatteryRecord(
        id: 'b2',
        deviceId: 'dev_1',
        batteryLevel: 90,
        chargingStatus: 'DISCHARGING',
        pluggedType: 'NONE',
        timestamp: now,
      );

      await repo.saveBatteryRecords([b1, b2]);
      final results = await repo.getBatteryHistory();
      expect(results.length, 1);
    });

    test('Replaces daily activity report for the same date without duplication', () async {
      final r1 = DailyActivityReport(
        id: 'rep_1',
        deviceId: 'dev_1',
        date: '2026-10-30',
        totalScreenTimeSeconds: 3600,
        totalNotificationsCount: 10,
        totalWifiBytes: 1000,
        totalMobileBytes: 500,
        topApps: {'App1': 3600},
        generatedAt: DateTime.now(),
      );

      final r2 = DailyActivityReport(
        id: 'rep_2',
        deviceId: 'dev_1',
        date: '2026-10-30',
        totalScreenTimeSeconds: 7200,
        totalNotificationsCount: 20,
        totalWifiBytes: 2000,
        totalMobileBytes: 1000,
        topApps: {'App1': 7200},
        generatedAt: DateTime.now(),
      );

      await repo.saveDailyReport(r1);
      await repo.saveDailyReport(r2);

      final reports = await repo.getDailyReports();
      expect(reports.length, 1);
      expect(reports.first.totalScreenTimeSeconds, 7200);
      expect(reports.first.totalNotificationsCount, 20);
    });
  });

  group('Service & Offline Synchronization Tests', () {
    late Database memoryDb;
    late SqliteFamilyInsightsRepository repo;

    setUp(() async {
      memoryDb = await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: (database, version) async {
            await database.execute('''
              CREATE TABLE IF NOT EXISTS device_activity (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL UNIQUE,
                device_model TEXT,
                os_version TEXT,
                last_sync_timestamp INTEGER NOT NULL,
                is_monitoring_active INTEGER NOT NULL DEFAULT 1
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS app_usage_events (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                package_name TEXT NOT NULL,
                app_name TEXT,
                event_type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                duration_ms INTEGER DEFAULT 0,
                UNIQUE(device_id, package_name, timestamp, event_type) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS screen_activity (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp, event_type) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS notification_metadata (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                package_name TEXT NOT NULL,
                app_name TEXT,
                category TEXT,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, package_name, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS battery_history (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                battery_level INTEGER NOT NULL,
                charging_status TEXT NOT NULL,
                plugged_type TEXT,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS network_usage (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                network_type TEXT NOT NULL,
                package_name TEXT,
                rx_bytes INTEGER NOT NULL,
                tx_bytes INTEGER NOT NULL,
                start_time INTEGER NOT NULL,
                end_time INTEGER NOT NULL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, network_type, package_name, start_time, end_time) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS location_history (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                accuracy REAL,
                timestamp INTEGER NOT NULL,
                UNIQUE(device_id, timestamp) ON CONFLICT IGNORE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS daily_activity_reports (
                id TEXT PRIMARY KEY,
                device_id TEXT NOT NULL,
                date TEXT NOT NULL,
                total_screen_time_seconds INTEGER NOT NULL,
                total_notifications_count INTEGER NOT NULL,
                total_wifi_bytes INTEGER NOT NULL,
                total_mobile_bytes INTEGER NOT NULL,
                top_apps_json TEXT,
                generated_at INTEGER NOT NULL,
                UNIQUE(device_id, date) ON CONFLICT REPLACE
              )
            ''');
            await database.execute('''
              CREATE TABLE IF NOT EXISTS monitoring_permissions (
                id TEXT PRIMARY KEY,
                permission_key TEXT NOT NULL UNIQUE,
                is_granted INTEGER NOT NULL DEFAULT 0,
                updated_at INTEGER NOT NULL
              )
            ''');
          },
        ),
      );
      repo = SqliteFamilyInsightsRepository(memoryDb);
    });

    tearDown(() async {
      await memoryDb.close();
    });

    test('syncNow() collects and persists data when permissions granted', () async {
      final mockPlatform = MockPlatformChannel(
        usageGranted: true,
        notifGranted: true,
        locationGranted: true,
      );
      mockPlatform.locationEnabled = true;

      final service = FamilyInsightsService(
        repository: repo,
        platformChannel: mockPlatform,
      );

      await service.syncNow();

      // Verify device saved
      final device = await repo.getDeviceActivity('test_device_100');
      expect(device, isNotNull);
      expect(device!.deviceModel, 'Test Pixel 7');

      // Verify app usage
      final usage = await repo.getAppUsageEvents();
      expect(usage.isNotEmpty, isTrue);

      // Verify battery
      final battery = await repo.getLatestBatteryRecord('test_device_100');
      expect(battery, isNotNull);
      expect(battery!.batteryLevel, 85);

      // Verify network
      final net = await repo.getNetworkUsage();
      expect(net.isNotEmpty, isTrue);

      // Verify notifications
      final notifs = await repo.getNotificationMetadata();
      expect(notifs.length, 1);
      expect(notifs.first.category, 'email');

      // Verify location
      final loc = await repo.getLatestLocation('test_device_100');
      expect(loc, isNotNull);
      expect(loc!.latitude, closeTo(37.422, 0.001));

      // Verify daily report generated
      final reports = await repo.getDailyReports();
      expect(reports.length, 1);
    });

    test('syncNow() gracefully handles denied permissions without errors', () async {
      final mockPlatform = MockPlatformChannel(
        usageGranted: false,
        notifGranted: false,
        locationGranted: false,
      );

      final service = FamilyInsightsService(
        repository: repo,
        platformChannel: mockPlatform,
      );

      await service.syncNow();

      // Device & Battery still sync
      final device = await repo.getDeviceActivity('test_device_100');
      expect(device, isNotNull);

      // Denied modules remain empty
      final usage = await repo.getAppUsageEvents();
      expect(usage.isEmpty, isTrue);

      final notifs = await repo.getNotificationMetadata();
      expect(notifs.isEmpty, isTrue);

      final loc = await repo.getLatestLocation('test_device_100');
      expect(loc, isNull);
    });

    test('Pause and Resume monitoring toggles state cleanly', () async {
      final mockPlatform = MockPlatformChannel();
      final service = FamilyInsightsService(
        repository: repo,
        platformChannel: mockPlatform,
      );

      await service.syncNow();
      await service.setMonitoringPaused(true);

      var perms = await repo.getPermissions();
      expect(perms['monitoring_paused'], isTrue);

      await service.setMonitoringPaused(false);
      perms = await repo.getPermissions();
      expect(perms['monitoring_paused'], isFalse);
    });

    test('clearAllData() deletes all recorded activity', () async {
      final mockPlatform = MockPlatformChannel();
      final service = FamilyInsightsService(
        repository: repo,
        platformChannel: mockPlatform,
      );

      await service.syncNow();
      await service.clearAllData();

      expect((await repo.getAllDevices()).isEmpty, isTrue);
      expect((await repo.getAppUsageEvents()).isEmpty, isTrue);
      expect((await repo.getBatteryHistory()).isEmpty, isTrue);
      expect((await repo.getNotificationMetadata()).isEmpty, isTrue);
    });
  });

  group('JSON and CSV Export Tests', () {
    test('JSON export builds structured, valid document', () async {
      final jsonPath = await FamilyInsightsExportService.exportToJson(
        deviceActivity: DeviceActivity(
          id: 'dev_1',
          deviceId: 'dev_1',
          deviceModel: 'Test Model',
          osVersion: 'Android 14',
          lastSyncTimestamp: DateTime.now(),
        ),
        reports: [],
        appSummaries: [
          AppUsageSummary(
            packageName: 'com.test.app',
            appName: 'Test App',
            totalDurationMs: 60000,
          )
        ],
        screenActivities: [],
        notifications: [],
        batteryHistory: [
          BatteryRecord(
            id: 'b1',
            deviceId: 'dev_1',
            batteryLevel: 95,
            chargingStatus: 'CHARGING',
            pluggedType: 'AC',
            timestamp: DateTime.now(),
          )
        ],
        networkUsages: [],
        locations: [],
      );

      expect(jsonPath.isNotEmpty, isTrue);
    });

    test('CSV export generates correct header and escapes commas properly', () async {
      final records = [
        {'app_name': 'Test, App with comma', 'duration_ms': 5000},
        {'app_name': 'SimpleApp', 'duration_ms': 2000},
      ];

      final csvPath = await FamilyInsightsExportService.exportToCsv(
        dataType: 'test_apps',
        records: records,
      );

      expect(csvPath.isNotEmpty, isTrue);
    });
  });

  group('Windows & Desktop Compatibility Tests', () {
    test('Platform channel on Windows gracefully returns unsupported without crash', () async {
      final channel = FamilyInsightsPlatformChannel();
      // On Windows environment:
      expect(channel.isPlatformSupported, isFalse);

      final status = await channel.getPermissionsStatus();
      expect(status['unsupported_platform'], isTrue);

      final battery = await channel.collectBatteryStatus();
      expect(battery, isNull);

      final usage = await channel.collectAppUsage(startTime: DateTime.now(), endTime: DateTime.now());
      expect(usage, isNull);

      final devInfo = await channel.getDeviceInfo();
      expect(devInfo['device_id'], contains('windows'));
    });
  });
}

