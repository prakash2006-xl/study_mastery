import 'package:sqflite/sqflite.dart';
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
    final dbPath = p.join(
      FilesystemService.appDocDir.path,
      'LearningOS_Data',
      'database.sqlite',
    );

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createSchema,
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    // Documents Table
    await db.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
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

    // Tasks Table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        due_date INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
  }
}
