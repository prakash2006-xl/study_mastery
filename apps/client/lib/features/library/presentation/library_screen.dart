import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../application/document_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    PlatformFile? result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      if (kIsWeb) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document Library is only supported on Desktop and Mobile apps.')),
        );
        return;
      }
      
      if (result.path != null) {
        final name = result.name;
        final path = result.path!;
        await ref.read(documentNotifierProvider.notifier).importDocument(name, path);
      }
    }
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Folder Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                ref.read(folderNotifierProvider.notifier).createFolder(textController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDocumentDialog(BuildContext context, WidgetRef ref, String id, String currentTitle) {
    final textController = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'Document Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                ref.read(documentNotifierProvider.notifier).renameDocument(id, textController.text);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentNotifierProvider);
    final foldersAsync = ref.watch(folderNotifierProvider);
    final currentFolderId = ref.watch(currentFolderIdProvider);

    final isLoading = docsAsync.isLoading || foldersAsync.isLoading;
    final folders = foldersAsync.valueOrNull ?? [];
    final docs = docsAsync.valueOrNull ?? [];
    final isEmpty = folders.isEmpty && docs.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Library'),
        leading: currentFolderId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // For simplicity, we just go back to root. A real stack could be used for nested folders.
                  ref.read(currentFolderIdProvider.notifier).state = null;
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            tooltip: 'Create Folder',
            onPressed: () => _showCreateFolderDialog(context, ref),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.library_books, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No documents or folders here.', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _importPdf(context, ref),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Import PDF'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: folders.length + docs.length,
                  itemBuilder: (context, index) {
                    if (index < folders.length) {
                      // Render Folder
                      final folder = folders[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: InkWell(
                          onTap: () {
                            ref.read(currentFolderIdProvider.notifier).state = folder.id;
                          },
                          onLongPress: () {
                            ref.read(folderNotifierProvider.notifier).deleteFolder(folder.id);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.folder, size: 64, color: Colors.amber),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  folder.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Render Document
                    final doc = docs[index - folders.length];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          context.push('/serious_study', extra: {
                            'filePath': doc.filePath,
                            'documentId': doc.id,
                          });
                        },
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.picture_as_pdf, size: 48, color: Colors.redAccent),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    doc.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showRenameDocumentDialog(context, ref, doc.id, doc.title);
                                  } else if (value == 'delete') {
                                    ref.read(documentNotifierProvider.notifier).deleteDocument(doc.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _importPdf(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Import PDF'),
      ),
    );
  }
}
