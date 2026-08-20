import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';

class Document {
  final String id;
  final String title;
  final String filePath;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;

  Document({
    required this.id,
    required this.title,
    required this.filePath,
    required this.addedAt,
    this.lastOpenedAt,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      filePath: map['file_path'],
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['added_at']),
      lastOpenedAt: map['last_opened_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_opened_at']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'added_at': addedAt.millisecondsSinceEpoch,
      'last_opened_at': lastOpenedAt?.millisecondsSinceEpoch,
    };
  }
}

class DocumentRepository {
  final Database _db;

  DocumentRepository(this._db);

  Future<void> insertDocument(Document document) async {
    await _db.insert(
      'documents',
      document.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Document>> getAllDocuments() async {
    final List<Map<String, dynamic>> maps = await _db.query('documents');
    return List.generate(maps.length, (i) {
      return Document.fromMap(maps[i]);
    });
  }
}

final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DocumentRepository(db);
});
