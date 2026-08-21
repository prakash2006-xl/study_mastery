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
        // Web does not support native file paths for the DB schema yet.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Library'),
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (docs) {
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.library_books, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No documents in your library.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _importPdf(context, ref),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import PDF'),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    // Navigate to Serious Study with the selected document
                    context.push('/serious_study', extra: {
                      'filePath': doc.filePath,
                      'documentId': doc.id,
                    });
                  },
                  child: Column(
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: docsAsync.maybeWhen(
        data: (docs) => docs.isNotEmpty
            ? FloatingActionButton.extended(
                onPressed: () => _importPdf(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Import'),
              )
            : null,
        orElse: () => null,
      ),
    );
  }
}
