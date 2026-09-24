class PlaylistItem {
  const PlaylistItem({
    required this.path,
    required this.title,
    this.position = Duration.zero,
  });

  final String path;
  final String title;
  final Duration position;

  PlaylistItem copyWith({Duration? position}) => PlaylistItem(
    path: path,
    title: title,
    position: position ?? this.position,
  );
}
