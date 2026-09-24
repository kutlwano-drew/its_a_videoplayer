import 'package:window_manager/window_manager.dart';

class WindowService {
  Future<void> toggleFullscreen() async {
    final fullscreen = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!fullscreen);
  }
}
