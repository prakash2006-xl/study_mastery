import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';

class Folder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  Folder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      parentId: map['parent_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class Document {
  final String id;
  final String title;
  final String filePath;
  final String? folderId;
  final DateTime addedAt;
  final DateTime? lastOpenedAt;

  Document({
    required this.id,
    required this.title,
    required this.filePath,
    this.folderId,
    required this.addedAt,
    this.lastOpenedAt,
  });

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      filePath: map['file_path'],
      folderId: map['folder_id'],
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
      'folder_id': folderId,
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

  Future<void> updateDocumentTitle(String id, String newTitle) async {
    await _db.update(
      'documents',
      {'title': newTitle},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateDocumentFolder(String id, String? newFolderId) async {
    await _db.update(
      'documents',
      {'folder_id': newFolderId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Document>> getAllDocuments({String? folderId}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'documents',
      where: folderId == null ? 'folder_id IS NULL' : 'folder_id = ?',
      whereArgs: folderId == null ? [] : [folderId],
    );
    return List.generate(maps.length, (i) {
      return Document.fromMap(maps[i]);
    });
  }

  Future<void> insertFolder(Folder folder) async {
    await _db.insert(
      'folders',
      folder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Folder>> getFolders({String? parentId}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'folders',
      where: parentId == null ? 'parent_id IS NULL' : 'parent_id = ?',
      whereArgs: parentId == null ? [] : [parentId],
    );
    return List.generate(maps.length, (i) {
      return Folder.fromMap(maps[i]);
    });
  }

  Future<void> deleteFolder(String folderId) async {
    await _db.delete('folders', where: 'id = ?', whereArgs: [folderId]);
  }

  Future<void> deleteDocument(String id) async {
    await _db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }
}

final documentRepositoryProvider = FutureProvider<DocumentRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return DocumentRepository(db);
});
