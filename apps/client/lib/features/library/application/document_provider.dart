import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/document_repository.dart';
import '../../../core/api/ai_gateway_service.dart';

final currentFolderIdProvider = StateProvider<String?>((ref) => null);

final folderNotifierProvider = AsyncNotifierProvider<FolderNotifier, List<Folder>>(() {
  return FolderNotifier();
});

class FolderNotifier extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() async {
    final parentId = ref.watch(currentFolderIdProvider);
    final repo = await ref.read(documentRepositoryProvider.future);
    final folders = await repo.getFolders(parentId: parentId);
    folders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return folders;
  }

  Future<void> createFolder(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      final parentId = ref.read(currentFolderIdProvider);
      final newFolder = Folder(
        id: const Uuid().v4(),
        name: name,
        parentId: parentId,
        createdAt: DateTime.now(),
      );
      await repo.insertFolder(newFolder);
      return build();
    });
  }

  Future<void> deleteFolder(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.deleteFolder(id);
      return build();
    });
  }
}

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
    final folderId = ref.watch(currentFolderIdProvider);
    final repo = await ref.read(documentRepositoryProvider.future);
    final docs = await repo.getAllDocuments(folderId: folderId);
    docs.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return docs;
  }

  Future<void> importDocument(String title, String filePath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      final folderId = ref.read(currentFolderIdProvider);
      final docId = const Uuid().v4();
      final newDoc = Document(
        id: docId,
        title: title,
        filePath: filePath,
        folderId: folderId,
        addedAt: DateTime.now(),
      );
      
      await repo.insertDocument(newDoc);
      
      print('Sending $docId to AI Gateway for indexing...');
      await _aiService.indexDocument(docId, filePath);
      
      return _fetchDocuments();
    });
  }

  Future<void> renameDocument(String id, String newTitle) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.updateDocumentTitle(id, newTitle);
      return _fetchDocuments();
    });
  }

  Future<void> moveDocument(String id, String? newFolderId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.updateDocumentFolder(id, newFolderId);
      return _fetchDocuments();
    });
  }

  Future<void> deleteDocument(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(documentRepositoryProvider.future);
      await repo.deleteDocument(id);
      return _fetchDocuments();
    });
  }
}
