import 'dart:io';

String fileName(String path) => path.split(Platform.pathSeparator).last;

/// Opens the containing folder for [path] and, where supported, selects the
/// file itself. This is intentionally desktop-only.
Future<void> revealFileInExplorer(String path) async {
  final file = File(path);

  if (!file.existsSync()) {
    return;
  }

  try {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,${file.path}']);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [file.parent.path]);
    }
  } catch (_) {
    // Opening the file manager is best-effort; never let it affect playback.
  }
}
