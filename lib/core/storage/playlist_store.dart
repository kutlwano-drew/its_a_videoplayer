import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistSnapshot {
  const PlaylistSnapshot({
    required this.name,
    required this.paths,
    required this.currentIndex,
    required this.currentPath,
    required this.playlistPositionSeconds,
    required this.itemPositions,
  });

  final String name;
  final List<String> paths;
  final int currentIndex;
  final String? currentPath;
  final double playlistPositionSeconds;
  final Map<String, double> itemPositions;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'name': name,
        'paths': paths,
        'currentIndex': currentIndex,
        'currentPath': currentPath,
        'playlistPositionSeconds': playlistPositionSeconds,
        'itemPositions': itemPositions,
      };

  factory PlaylistSnapshot.fromJson(Map<String, dynamic> json) {
    final rawPositions = json['itemPositions'];
    final positions = rawPositions is Map
        ? rawPositions.map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          )
        : <String, double>{};

    return PlaylistSnapshot(
      name: json['name'] as String? ?? 'Playlist',
      paths: (json['paths'] as List? ?? const []).whereType<String>().toList(),
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? -1,
      currentPath: json['currentPath'] as String?,
      playlistPositionSeconds:
          (json['playlistPositionSeconds'] as num?)?.toDouble() ?? 0,
      itemPositions: positions,
    );
  }
}

class PlaylistStore {
  static const _lastPlaylistKey = 'last_playlist';

  Future<void> remember(PlaylistSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlaylistKey, jsonEncode(snapshot.toJson()));
  }

  Future<PlaylistSnapshot?> restoreLast() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastPlaylistKey);
    if (raw == null) return null;
    try {
      return PlaylistSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Uri?> saveToFile(PlaylistSnapshot snapshot) async {
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(snapshot.toJson())),
    );
    return FilePicker.saveFile(
      dialogTitle: 'Save playlist',
      fileName: '${_safeFileName(snapshot.name)}.json',
      bytes: bytes,
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
  }

  Future<PlaylistSnapshot?> loadFromFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = file?.path;
    if (path == null) return null;

    try {
      final text = await File(path).readAsString();
      return PlaylistSnapshot.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String _safeFileName(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'playlist' : cleaned;
  }
}
