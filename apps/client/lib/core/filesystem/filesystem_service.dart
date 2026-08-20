import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FilesystemService {
  static late Directory appDocDir;
  static late String originalPdfsPath;
  static late String scribblesTempPath;
  static late String voiceNotesPath;

  static Future<void> initialize() async {
    appDocDir = await getApplicationDocumentsDirectory();
    final basePath = p.join(appDocDir.path, 'LearningOS_Data');

    originalPdfsPath = p.join(basePath, 'Original_PDFs');
    scribblesTempPath = p.join(basePath, 'Scribbles_Temp');
    voiceNotesPath = p.join(basePath, 'Voice_Notes');

    await _ensureDirectory(basePath);
    await _ensureDirectory(originalPdfsPath);
    await _ensureDirectory(scribblesTempPath);
    await _ensureDirectory(voiceNotesPath);
  }

  static Future<void> _ensureDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }
}
