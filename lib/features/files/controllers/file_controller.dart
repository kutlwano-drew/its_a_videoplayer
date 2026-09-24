import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/services/file_service.dart';

class FileController extends ChangeNotifier {
  FileController({FileService? service}) : _service = service ?? FileService();

  final FileService _service;

  Future<List<File>> pickVideos() => _service.pickVideos();
  Future<File?> pickSubtitle() => _service.pickSubtitle();
}
