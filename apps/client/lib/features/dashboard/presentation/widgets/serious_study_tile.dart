import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../library/application/document_provider.dart';

import 'package:file_picker/file_picker.dart';

class SeriousStudyTile extends ConsumerWidget {
  const SeriousStudyTile({super.key});

  void _pickFromDevice(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.path != null) {
        final path = result.path!;
        final name = result.name;
        // Import it to library
        final docId = await ref.read(documentNotifierProvider.notifier).importDocument(name, path);
        
        if (context.mounted) {
          Navigator.pop(context); // Close dialog
          context.push('/serious_study', extra: {
            'filePath': path,
            'documentId': docId,
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDocumentPicker(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.read(documentNotifierProvider);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Document for Deep Study'),
          content: SizedBox(
            width: double.maxFinite,
            height: 350,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open, color: Colors.blue),
                  title: const Text('Pick from Device...', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _pickFromDevice(ctx, ref),
                ),
                const Divider(),
                Expanded(
                  child: docsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, st) => const Center(child: Text('Error loading library')),
                    data: (docs) {
                      if (docs.isEmpty) {
                        return const Center(child: Text('No documents found in Library.', textAlign: TextAlign.center));
                      }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (ctx, index) {
                    final doc = docs[index];
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      title: Text(doc.title),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push('/serious_study', extra: {
                          'filePath': doc.filePath,
                          'documentId': doc.id,
                        });
                      },
                    );
                  },
                );
              },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Serious Study Button
        Expanded(
          child: InkWell(
            onTap: () => _showDocumentPicker(context, ref),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Serious Study',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Enter deep work mode.',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Scribble Button
        Expanded(
          child: InkWell(
            onTap: () {
              context.push('/scribble');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.tertiary.withOpacity(0.8),
                    theme.colorScheme.tertiary.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.tertiary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.draw, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Scribble',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Take digital notes quickly.',
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
