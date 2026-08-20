import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class SeriousStudyScreen extends StatefulWidget {
  const SeriousStudyScreen({super.key});

  @override
  State<SeriousStudyScreen> createState() => _SeriousStudyScreenState();
}

class _SeriousStudyScreenState extends State<SeriousStudyScreen> {
  late PdfController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfController(
      document: PdfDocument.openAsset('assets/sample.pdf'),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serious Study Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI Companion',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Companion: How can I help you study?')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Voice Note',
            onPressed: () {},
          ),
        ],
      ),
      body: PdfView(
        controller: _pdfController,
        scrollDirection: Axis.vertical,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Stub for adding annotations
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annotation mode enabled')),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
