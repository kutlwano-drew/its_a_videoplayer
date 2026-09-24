import 'package:media_kit/media_kit.dart';

class PlayerService {
  PlayerService() : player = Player();

  final Player player;

  Future<void> open(String path) async {
    await player.open(Media(path), play: true);
  }

  Future<void> dispose() => player.dispose();
}
