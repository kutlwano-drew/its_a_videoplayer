import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/shortcut_defaults.dart';
import '../../../core/storage/shortcut_store.dart';

class ShortcutController extends ChangeNotifier {
  ShortcutController({ShortcutStore? store})
      : _store = store ?? ShortcutStore(),
        _values = Map.of(ShortcutDefaults.values) {
    _load();
  }

  final ShortcutStore _store;
  final Map<String, String> _values;

  Map<String, String> get values => Map.unmodifiable(_values);

  Future<void> _load() async {
    final saved = await _store.load();
    if (saved != null) {
      _values
        ..clear()
        ..addAll(ShortcutDefaults.values)
        ..addAll(saved);
      notifyListeners();
    }
  }

  bool setShortcut(String action, String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) return false;
    final conflict = _values.entries.any(
      (entry) => entry.key != action &&
          entry.value.toLowerCase() == normalized.toLowerCase(),
    );
    if (conflict) return false;
    _values[action] = normalized;
    _store.save(_values);
    notifyListeners();
    return true;
  }

  String? actionForEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return null;
    final key = event.logicalKey;
    final control = HardwareKeyboard.instance.isControlPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;

    if (control && key == LogicalKeyboardKey.keyO) return 'Open File';
    if (control && key == LogicalKeyboardKey.keyL) return 'Toggle Playlist';
    if (control && key == LogicalKeyboardKey.arrowUp) return 'Volume Up';
    if (control && key == LogicalKeyboardKey.arrowDown) return 'Volume Down';
    if (control && key == LogicalKeyboardKey.arrowLeft) return 'Seek Backward 5m';
    if (control && key == LogicalKeyboardKey.arrowRight) return 'Seek Forward 5m';
    if (alt && key == LogicalKeyboardKey.arrowLeft) return 'Seek Backward 1m';
    if (alt && key == LogicalKeyboardKey.arrowRight) return 'Seek Forward 1m';
    if (shift && key == LogicalKeyboardKey.arrowLeft) return 'Seek Backward 10s';
    if (shift && key == LogicalKeyboardKey.arrowRight) return 'Seek Forward 10s';
    if (key == LogicalKeyboardKey.space) return 'Play / Pause';
    if (key == LogicalKeyboardKey.escape) return 'Exit Fullscreen';
    if (key == LogicalKeyboardKey.keyF) return 'Fullscreen';
    if (key == LogicalKeyboardKey.keyS) return 'Stop';
    if (key == LogicalKeyboardKey.keyM) return 'Mute';
    if (key == LogicalKeyboardKey.keyN) return 'Next Video';
    if (key == LogicalKeyboardKey.keyP) return 'Previous Video';
    if (key == LogicalKeyboardKey.keyR) return 'Repeat Mode';
    if (key == LogicalKeyboardKey.keyA) return 'Rewind';
    if (key == LogicalKeyboardKey.keyD) return 'Fast Forward';
    if (key == LogicalKeyboardKey.keyT) return 'Audio Track';
    if (key == LogicalKeyboardKey.keyC) return 'Crop Mode';
    if (key == LogicalKeyboardKey.keyI) return 'Seek Forward 10s';
    if (key == LogicalKeyboardKey.keyJ) return 'Seek Backward 10s';
    if (key == LogicalKeyboardKey.arrowLeft) return 'Seek Backward 3s';
    if (key == LogicalKeyboardKey.arrowRight) return 'Seek Forward 3s';
    if (key == LogicalKeyboardKey.arrowUp) return 'Volume Up 5%';
    if (key == LogicalKeyboardKey.arrowDown) return 'Volume Down 5%';
    if (key == LogicalKeyboardKey.home) return 'Jump To Start';
    if (key == LogicalKeyboardKey.end) return 'Jump To End';
    if (key == LogicalKeyboardKey.bracketLeft) return 'Set A';
    if (key == LogicalKeyboardKey.bracketRight) return 'Set B';
    if (key == LogicalKeyboardKey.backslash) return 'Clear A-B';
    if (key == LogicalKeyboardKey.add || (key == LogicalKeyboardKey.equal && shift)) return 'Faster';
    if (key == LogicalKeyboardKey.minus) return 'Slower';
    if (key == LogicalKeyboardKey.equal) return 'Normal Speed';
    return null;
  }
}
