import 'dart:io';

import 'package:file_picker/file_picker.dart';

class FileService {
  Future<List<File>> pickVideos() async {
    final files = await FilePicker.pickFiles(
      type: FileType.video,
    );

    return files
        .map((file) => file.path)
        .whereType<String>()
        .map(File.new)
        .where((file) => file.existsSync())
        .toList();
  }

  Future<File?> pickSubtitle() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'ssa', 'vtt', 'sub'],
    );
    final path = file?.path;
    if (path == null) return null;
    final subtitle = File(path);
    return subtitle.existsSync() ? subtitle : null;
  }
}
