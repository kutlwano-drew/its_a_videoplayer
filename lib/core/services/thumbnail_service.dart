import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:media_kit/media_kit.dart';

class ThumbnailService {
  ThumbnailService._();

  static final ThumbnailService instance = ThumbnailService._();

  // Keep the thumbnail cache bounded. A playlist can be large without
  // retaining decoded thumbnail bytes for every item in memory.
  static const int _maxCachedThumbnails = 24;
  static const int _maxConcurrentCreates = 2;

  final LinkedHashMap<String, Future<Uint8List?>> _cache =
      LinkedHashMap<String, Future<Uint8List?>>();
  final Set<String> _pending = <String>{};
  final Queue<_ThumbnailJob> _queue = Queue<_ThumbnailJob>();

  int _activeCreates = 0;

  Future<Uint8List?> thumbnail(String path) {
    final cached = _cache[path];
    if (cached != null) {
      // Touch the entry so frequently visible thumbnails stay warm.
      _cache.remove(path);
      _cache[path] = cached;
      return cached;
    }

    final completer = Completer<Uint8List?>();
    _cache[path] = completer.future;
    _pending.add(path);
    _queue.add(_ThumbnailJob(path, completer));
    _pump();

    return completer.future;
  }

  void _pump() {
    while (_activeCreates < _maxConcurrentCreates && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _activeCreates++;

      _create(job.path).then(
        (bytes) {
          if (!job.completer.isCompleted) {
            job.completer.complete(bytes);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!job.completer.isCompleted) {
            // A missing/corrupt media file should only lose its thumbnail.
            job.completer.complete(null);
          }
        },
      ).whenComplete(() {
        _activeCreates--;
        _pending.remove(job.path);
        _trimCache();
        _pump();
      });
    }
  }

  void _trimCache() {
    if (_cache.length <= _maxCachedThumbnails) {
      return;
    }

    final keys = List<String>.from(_cache.keys);
    for (final key in keys) {
      if (_cache.length <= _maxCachedThumbnails) {
        break;
      }

      // Never evict a thumbnail that is still being generated.
      if (_pending.contains(key)) {
        continue;
      }

      _cache.remove(key);
    }
  }

  Future<Uint8List?> _create(String path) async {
    final player = Player();

    try {
      await player.open(Media(path), play: false);
      await player.stream.width
          .firstWhere((value) => value != null && value > 0)
          .timeout(const Duration(seconds: 4));

      return await player.screenshot(format: 'image/jpeg');
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }

  void clear(String path) {
    if (_pending.contains(path)) {
      return;
    }

    _cache.remove(path);
  }

  void clearAll() {
    final pending = Set<String>.from(_pending);
    _cache.removeWhere((key, _) => !pending.contains(key));
  }
}

class _ThumbnailJob {
  const _ThumbnailJob(this.path, this.completer);

  final String path;
  final Completer<Uint8List?> completer;
}
