import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

class SubtitleController extends ChangeNotifier {
  SubtitleController(this.player);

  final Player player;
  Duration _delay = Duration.zero;
  int _selectedTrack = 0;

  Duration get delay => _delay;
  int get selectedTrack => _selectedTrack;

  Future<void> setDelay(Duration value) async {
    _delay = value;
    // media_kit 1.2.6 does not expose subtitle delay as a high-level
    // Player method. Keep the setting at application level until a
    // verified libmpv/native command bridge is introduced.
    notifyListeners();
  }

  void setSelectedTrack(int index) {
    _selectedTrack = index;
    notifyListeners();
  }

  Future<void> selectTrack(SubtitleTrack track) async {
    await player.setSubtitleTrack(track);
    notifyListeners();
  }
}
