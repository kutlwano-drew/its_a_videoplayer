import 'app_error.dart';

String friendlyErrorMessage(AppError error) {
  switch (error.code) {
    case AppErrorCode.fileOpen:
      return 'The selected file could not be opened.';
    case AppErrorCode.mediaLoad:
      return 'This video could not be loaded. It may be unsupported or damaged.';
    case AppErrorCode.mediaPlayback:
      return 'Playback encountered an error.';
    case AppErrorCode.subtitle:
      return 'The subtitle file could not be loaded.';
    case AppErrorCode.playlist:
      return 'The playlist could not be updated.';
    case AppErrorCode.storage:
      return 'Settings could not be saved. Playback will continue normally.';
    case AppErrorCode.unknown:
      return 'Something went wrong.';
  }
}
