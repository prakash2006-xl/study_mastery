import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/document_repository.dart';
import '../../../core/api/ai_gateway_service.dart';

final documentNotifierProvider = AsyncNotifierProvider<DocumentNotifier, List<Document>>(() {
  return DocumentNotifier();
});

class DocumentNotifier extends AsyncNotifier<List<Document>> {
  final AiGatewayService _aiService = AiGatewayService();

  @override
  Future<List<Document>> build() async {
    return _fetchDocuments();
  }

  Future<List<Document>> _fetchDocuments() async {
    final repo = await ref.read(documentRepositoryProvider.future);
    final docs = await repo.getAllDocuments();
    docs.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return docs;
  }

  Future<void> importDocument(String title, String filePath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      final docId = const Uuid().v4();
      final newDoc = Document(
        id: docId,
        title: title,
        filePath: filePath,
        addedAt: DateTime.now(),
      );
      
      // Save locally
      await repo.insertDocument(newDoc);
      
      // Index remotely to AI FAISS
      print('Sending $docId to AI Gateway for indexing...');
      await _aiService.indexDocument(docId, filePath);
      
      return _fetchDocuments();
    });
  }
}
