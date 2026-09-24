enum AppErrorCode {
  fileOpen,
  mediaLoad,
  mediaPlayback,
  subtitle,
  playlist,
  storage,
  unknown,
}

class AppError {
  const AppError({
    required this.code,
    required this.message,
    this.details,
  });

  final AppErrorCode code;
  final String message;
  final String? details;
}
