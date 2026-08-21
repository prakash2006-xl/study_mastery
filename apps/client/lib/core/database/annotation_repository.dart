import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'database_provider.dart';

class StudyAnnotation {
  final String id;
  final String documentId;
  final int page;
  final String type; // 'pen', 'highlighter', 'sticky_note', 'bookmark', 'rectangle', 'circle', 'line', 'arrow'
  final String? geometry; // JSON string of coordinates/colors
  final String? content; // Text content if any
  final DateTime createdAt;

  StudyAnnotation({
    required this.id,
    required this.documentId,
    required this.page,
    required this.type,
    this.geometry,
    this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'page': page,
      'type': type,
      'geometry': geometry,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory StudyAnnotation.fromMap(Map<String, dynamic> map) {
    return StudyAnnotation(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      page: map['page'] as int,
      type: map['type'] as String,
      geometry: map['geometry'] as String?,
      content: map['content'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}

class AnnotationRepository {
  final Database db;

  AnnotationRepository(this.db);

  Future<void> insertAnnotation(StudyAnnotation annotation) async {
    await db.insert(
      'annotations',
      annotation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudyAnnotation>> getAnnotationsForDocument(String documentId, {int? page}) async {
    List<Map<String, dynamic>> maps;
    if (page != null) {
      maps = await db.query(
        'annotations',
        where: 'document_id = ? AND page = ?',
        whereArgs: [documentId, page],
        orderBy: 'created_at ASC',
      );
    } else {
      maps = await db.query(
        'annotations',
        where: 'document_id = ?',
        whereArgs: [documentId],
        orderBy: 'created_at ASC',
      );
    }
    return maps.map((map) => StudyAnnotation.fromMap(map)).toList();
  }

  Future<void> deleteAnnotation(String id) async {
    await db.delete(
      'annotations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAnnotationsForDocument(String documentId) async {
    await db.delete(
      'annotations',
      where: 'document_id = ?',
      whereArgs: [documentId],
    );
  }
}

final annotationRepositoryProvider = Provider<AnnotationRepository>((ref) {
  final db = ref.watch(databaseProvider).value;
  if (db == null) throw Exception('Database not initialized');
  return AnnotationRepository(db);
});
