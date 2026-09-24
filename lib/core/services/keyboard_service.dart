import 'package:flutter/services.dart';

class KeyboardService {
  String displayName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.arrowLeft) return 'Arrow Left';
    if (key == LogicalKeyboardKey.arrowRight) return 'Arrow Right';
    if (key == LogicalKeyboardKey.arrowUp) return 'Arrow Up';
    if (key == LogicalKeyboardKey.arrowDown) return 'Arrow Down';
    return key.keyLabel.isEmpty ? key.debugName ?? 'Unknown' : key.keyLabel;
  }
}
