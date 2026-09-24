import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/storage/playlist_store.dart';
import '../../../core/utils/file_utils.dart';
import '../models/playlist_item.dart';

class PlaylistController extends ChangeNotifier {
  PlaylistController({PlaylistStore? store}) : _store = store ?? PlaylistStore();

  final PlaylistStore _store;
  final List<PlaylistItem> _items = [];
  final Map<String, Duration> _positions = {};
  int _currentIndex = -1;
  String _name = 'My Playlist';
  String? _savedFilePath;

  List<PlaylistItem> get items => List.unmodifiable(_items);
  int get currentIndex => _currentIndex;
  String get name => _name;
  String? get savedFilePath => _savedFilePath;
  bool get isEmpty => _items.isEmpty;

  Future<void> restoreLast() async {
    final snapshot = await _store.restoreLast();
    if (snapshot != null) {
      await loadSnapshot(snapshot);
    }
  }

  Future<void> addFiles(List<File> files) async {
    for (final file in files) {
      if (_items.any((item) => item.path == file.path)) continue;
      _items.add(PlaylistItem(path: file.path, title: fileName(file.path)));
    }
    await _remember();
    notifyListeners();
  }

  Future<void> loadSnapshot(PlaylistSnapshot snapshot) async {
    _items
      ..clear()
      ..addAll(
        snapshot.paths
            .where((path) => File(path).existsSync())
            .map((path) => PlaylistItem(
                  path: path,
                  title: fileName(path),
                  position: Duration(
                    milliseconds: ((snapshot.itemPositions[path] ?? 0) * 1000).round(),
                  ),
                )),
      );
    _positions
      ..clear()
      ..addAll(
        snapshot.itemPositions.map(
          (path, seconds) => MapEntry(
            path,
            Duration(milliseconds: (seconds * 1000).round()),
          ),
        ),
      );
    _name = snapshot.name;
    if (_items.isEmpty || snapshot.currentIndex < 0) {
      _currentIndex = -1;
    } else {
      _currentIndex = snapshot.currentIndex > _items.length - 1
          ? _items.length - 1
          : snapshot.currentIndex;
    }
    if (snapshot.currentPath != null) {
      final found = indexOf(snapshot.currentPath!);
      if (found >= 0) _currentIndex = found;
    }
    await _remember();
    notifyListeners();
  }

  Future<PlaylistSnapshot?> loadFromFile() async {
    final snapshot = await _store.loadFromFile();
    if (snapshot == null) return null;
    await loadSnapshot(snapshot);
    return snapshot;
  }

  Future<Uri?> saveToFile({Duration currentPosition = Duration.zero}) async {
    final snapshot = buildSnapshot(currentPosition: currentPosition);
    final uri = await _store.saveToFile(snapshot);
    if (uri != null) {
      _savedFilePath = uri.toFilePath();
      _name = _nameFromPath(_savedFilePath!);
      await _remember();
      notifyListeners();
    }
    return uri;
  }

  Future<void> persistSavedFile({Duration currentPosition = Duration.zero}) async {
    final path = _savedFilePath;
    if (path == null || _items.isEmpty) return;
    final snapshot = buildSnapshot(currentPosition: currentPosition);
    final file = File(path);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
    );
  }

  PlaylistSnapshot buildSnapshot({Duration currentPosition = Duration.zero}) {
    final positions = <String, double>{
      for (final entry in _positions.entries)
        entry.key: entry.value.inMilliseconds / 1000.0,
    };
    if (_currentIndex >= 0 && _currentIndex < _items.length && currentPosition > Duration.zero) {
      final path = _items[_currentIndex].path;
      positions[path] = currentPosition.inMilliseconds / 1000.0;
    }

    return PlaylistSnapshot(
      name: _name,
      paths: _items.map((item) => item.path).toList(),
      currentIndex: _currentIndex,
      currentPath: _currentIndex >= 0 && _currentIndex < _items.length
          ? _items[_currentIndex].path
          : null,
      playlistPositionSeconds: currentPosition.inMilliseconds / 1000.0,
      itemPositions: positions,
    );
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _items.length) return;
    final removed = _items.removeAt(index);
    _positions.remove(removed.path);
    if (_currentIndex == index) {
      _currentIndex = _items.isEmpty
          ? -1
          : (index > _items.length - 1 ? _items.length - 1 : index);
    } else if (_currentIndex > index) {
      _currentIndex--;
    }
    await _remember();
    notifyListeners();
  }

  Future<void> clear() async {
    _items.clear();
    _positions.clear();
    _currentIndex = -1;
    await _remember();
    notifyListeners();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    if (newIndex > _items.length) newIndex = _items.length;
    if (oldIndex < newIndex) newIndex--;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }
    await _remember();
    notifyListeners();
  }

  void setCurrent(int index) {
    if (index < 0 || index >= _items.length) return;
    _currentIndex = index;
    notifyListeners();
    _remember();
  }

  void setPosition(String path, Duration position) {
    _positions[path] = position;
    final index = indexOf(path);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(position: position);
    }
  }

  Duration positionFor(String path) => _positions[path] ?? Duration.zero;

  int indexOf(String path) => _items.indexWhere((item) => item.path == path);

  int nextIndex({bool wrap = false}) {
    if (_items.isEmpty || _currentIndex < 0) return -1;
    final next = _currentIndex + 1;
    if (next < _items.length) return next;
    return wrap ? 0 : -1;
  }

  int previousIndex({bool wrap = false}) {
    if (_items.isEmpty || _currentIndex < 0) return -1;
    final previous = _currentIndex - 1;
    if (previous >= 0) return previous;
    return wrap ? _items.length - 1 : -1;
  }

  Future<void> _remember() => _store.remember(buildSnapshot());

  String _nameFromPath(String path) {
    final base = path.split(Platform.pathSeparator).last;
    return base.toLowerCase().endsWith('.json')
        ? base.substring(0, base.length - 5)
        : base;
  }
}
