import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/annotation_repository.dart';
import '../../../core/database/database_provider.dart';
import 'dart:convert';

// We manage annotations per document
final annotationNotifierProvider = AsyncNotifierProviderFamily<AnnotationNotifier, List<StudyAnnotation>, String>(() {
  return AnnotationNotifier();
});

class AnnotationNotifier extends FamilyAsyncNotifier<List<StudyAnnotation>, String> {
  late AnnotationRepository _repository;
  late String _documentId;
  
  final List<StudyAnnotation> _undoStack = [];
  final List<StudyAnnotation> _redoStack = [];

  @override
  Future<List<StudyAnnotation>> build(String arg) async {
    _documentId = arg;
    _undoStack.clear();
    _redoStack.clear();
    
    // Wait for DB to initialize
    final db = await ref.watch(databaseProvider.future);
    _repository = AnnotationRepository(db);

    return _repository.getAnnotationsForDocument(_documentId);
  }

  Future<void> addAnnotation({
    required int page,
    required String type,
    String? geometry,
    String? content,
  }) async {
    final annotation = StudyAnnotation(
      id: const Uuid().v4(),
      documentId: _documentId,
      page: page,
      type: type,
      geometry: geometry,
      content: content,
      createdAt: DateTime.now(),
    );

    await _repository.insertAnnotation(annotation);
    
    _undoStack.add(annotation);
    _redoStack.clear(); // Clear redo stack on new action
    
    // Update state
    final previousState = await future;
    state = AsyncData([...previousState, annotation]);
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    
    final annotation = _undoStack.removeLast();
    await _repository.deleteAnnotation(annotation.id);
    _redoStack.add(annotation);
    
    final previousState = await future;
    state = AsyncData(previousState.where((a) => a.id != annotation.id).toList());
  }
  
  Future<void> redo() async {
    if (_redoStack.isEmpty) return;
    
    final annotation = _redoStack.removeLast();
    await _repository.insertAnnotation(annotation);
    _undoStack.add(annotation);
    
    final previousState = await future;
    state = AsyncData([...previousState, annotation]);
  }

  Future<void> deleteAnnotation(String id) async {
    await _repository.deleteAnnotation(id);
    final previousState = await future;
    state = AsyncData(previousState.where((a) => a.id != id).toList());
  }

  Future<void> clearAnnotations() async {
    await _repository.clearAnnotationsForDocument(_documentId);
    _undoStack.clear();
    _redoStack.clear();
    state = const AsyncData([]);
  }
}
