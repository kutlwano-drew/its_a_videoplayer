import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:its_a_videoplayer/features/player/controllers/player_controller.dart';

class ABLoopController extends ChangeNotifier {
  ABLoopController(this.player) {
    _sub = player.player.stream.position.listen(_onPosition);
  }

  final PlayerController player;

  StreamSubscription<Duration>? _sub;

  Duration? a;
  Duration? b;

  bool get aSet => a != null;
  bool get bSet => b != null;
  bool get active => a != null && b != null;

  void setA() {
    a = player.state.position;

    if (b != null && b! <= a!) {
      b = null;
    }

    notifyListeners();
  }

  void setB() {
    if (a == null) {
      return;
    }

    final position = player.state.position;

    if (position <= a!) {
      return;
    }

    b = position;
    notifyListeners();
  }

  void clear() {
    a = null;
    b = null;
    notifyListeners();
  }

  Future<void> _onPosition(Duration position) async {
    if (a != null && b != null && position >= b!) {
      await player.seek(a!);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
