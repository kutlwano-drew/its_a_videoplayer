bool looksLikeVideo(String path) {
  const extensions = {
    '.mp4', '.mkv', '.avi', '.mov', '.webm', '.m4v', '.wmv', '.flv', '.mpeg',
    '.mpg', '.ts', '.m2ts', '.3gp',
  };
  final lower = path.toLowerCase();
  return extensions.any(lower.endsWith);
}
