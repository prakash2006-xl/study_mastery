import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart' as p;
import '../filesystem/filesystem_service.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  @visibleForTesting
  static set testDatabase(Database? db) {
    _database = db;
  }

  static Future<Database> _initDB() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'database.sqlite',
        options: OpenDatabaseOptions(
          version: 4,
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema,
        ),
      );
    }
    
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final basePath = FilesystemService.appDocDir?.path ?? Directory.systemTemp.path;
    final dbPath = p.join(
      basePath,
      'LearningOS_Data',
      'database.sqlite',
    );

    return await openDatabase(
      dbPath,
      version: 4,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
  }

  @visibleForTesting
  static Future<void> createSchemaForTesting(Database db, int version) => _createSchema(db, version);

  @visibleForTesting
  static Future<void> upgradeSchemaForTesting(Database db, int oldVersion, int newVersion) => _upgradeSchema(db, oldVersion, newVersion);

  static Future<void> _createSchema(Database db, int version) async {
    // Folders Table
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_id TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // Documents Table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        folder_id TEXT,
        added_at INTEGER NOT NULL,
        last_opened_at INTEGER
      )
    ''');

    // Annotations Table
    await db.execute('''
      CREATE TABLE annotations (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        page INTEGER NOT NULL,
        type TEXT NOT NULL,
        geometry TEXT,
        content TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');

    // Tasks Table (v3 includes category and priority)
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        created_at INTEGER NOT NULL,
        category TEXT DEFAULT 'General',
        priority TEXT DEFAULT 'Medium'
      )
    ''');

    // --- Tables for Dashboard (v3) ---

    await db.execute('''
      CREATE TABLE alarms (
        id TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        time_milliseconds INTEGER NOT NULL,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        duration_seconds INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule_items (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        scheduled_time INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quick_notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE activity_logs (
        id TEXT PRIMARY KEY,
        description TEXT NOT NULL,
        icon_type TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // --- Family Insights Tables (v4) ---
    await _createFamilyInsightsTables(db);
  }

  static Future<void> _createFamilyInsightsTables(Database db) async {
    // 1. Device Activity
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_activity (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL UNIQUE,
        device_model TEXT,
        os_version TEXT,
        last_sync_timestamp INTEGER NOT NULL,
        is_monitoring_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 2. App Usage Events
    await db.execute('''
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_events_ts ON app_usage_events(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_events_pkg ON app_usage_events(package_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_app_usage_events_dev ON app_usage_events(device_id)');

    // 3. Screen Activity
    await db.execute('''
      CREATE TABLE IF NOT EXISTS screen_activity (
        id TEXT PRIMARY KEY,
        device_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        UNIQUE(device_id, timestamp, event_type) ON CONFLICT IGNORE
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_screen_activity_ts ON screen_activity(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_screen_activity_dev ON screen_activity(device_id)');

    // 4. Notification Metadata (STRICT: no private content)
    await db.execute('''
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_metadata_ts ON notification_metadata(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_metadata_pkg ON notification_metadata(package_name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_notification_metadata_dev ON notification_metadata(device_id)');

    // 5. Battery History
    await db.execute('''
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_battery_history_ts ON battery_history(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_battery_history_dev ON battery_history(device_id)');

    // 6. Network Usage
    await db.execute('''
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_network_usage_ts ON network_usage(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_network_usage_dev ON network_usage(device_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_network_usage_pkg ON network_usage(package_name)');

    // 7. Location History (Optional, strictly user permitted)
    await db.execute('''
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_location_history_ts ON location_history(timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_location_history_dev ON location_history(device_id)');

    // 8. Daily Activity Reports
    await db.execute('''
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_activity_reports_date ON daily_activity_reports(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_daily_activity_reports_dev ON daily_activity_reports(device_id)');

    // 9. Monitoring Permissions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS monitoring_permissions (
        id TEXT PRIMARY KEY,
        permission_key TEXT NOT NULL UNIQUE,
        is_granted INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_monitoring_permissions_key ON monitoring_permissions(permission_key)');
  }

  static Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          parent_id TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      try {
        await db.execute('ALTER TABLE documents ADD COLUMN folder_id TEXT');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT 'General'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE tasks ADD COLUMN priority TEXT DEFAULT 'Medium'");
      } catch (_) {}
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS alarms (
          id TEXT PRIMARY KEY,
          label TEXT NOT NULL,
          time_milliseconds INTEGER NOT NULL,
          is_enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS study_sessions (
          id TEXT PRIMARY KEY,
          start_time INTEGER NOT NULL,
          end_time INTEGER NOT NULL,
          duration_seconds INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS schedule_items (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          scheduled_time INTEGER NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quick_notes (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS activity_logs (
          id TEXT PRIMARY KEY,
          description TEXT NOT NULL,
          icon_type TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await _createFamilyInsightsTables(db);
    }
  }
}
