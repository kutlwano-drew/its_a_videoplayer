class SubtitleTrack {
  const SubtitleTrack({
    required this.id,
    required this.title,
    this.externalPath,
  });

  final int id;
  final String title;
  final String? externalPath;
}
