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

  static Future<Database> _initDB() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        'database.sqlite',
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _createSchema,
          onUpgrade: _upgradeSchema,
        ),
      );
    }
    
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    
    final dbPath = p.join(
      FilesystemService.appDocDir!.path,
      'LearningOS_Data',
      'database.sqlite',
    );

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
  }

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

    // --- New Tables for Dashboard (v3) ---

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
  }

  static Future<void> _upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          parent_id TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
      await db.execute('ALTER TABLE documents ADD COLUMN folder_id TEXT');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT 'General'");
      await db.execute("ALTER TABLE tasks ADD COLUMN priority TEXT DEFAULT 'Medium'");
      
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
    }
  }
}
