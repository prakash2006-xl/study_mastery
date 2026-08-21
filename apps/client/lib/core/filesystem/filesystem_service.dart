import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FilesystemService {
  static Directory? appDocDir;
  static String? originalPdfsPath;
  static String? scribblesTempPath;
  static String? voiceNotesPath;

  static Future<void> initialize() async {
    if (kIsWeb) return; // Web does not support dart:io Directory or path_provider
    appDocDir = await getApplicationDocumentsDirectory();
    final basePath = p.join(appDocDir!.path, 'LearningOS_Data');

    originalPdfsPath = p.join(basePath, 'Original_PDFs');
    scribblesTempPath = p.join(basePath, 'Scribbles_Temp');
    voiceNotesPath = p.join(basePath, 'Voice_Notes');

    await _ensureDirectory(basePath);
    await _ensureDirectory(originalPdfsPath!);
    await _ensureDirectory(scribblesTempPath!);
    await _ensureDirectory(voiceNotesPath!);
  }

  static Future<void> _ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
