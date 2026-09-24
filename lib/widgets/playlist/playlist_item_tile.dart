import 'package:flutter/material.dart';

class PlaylistItemTile extends StatelessWidget {
  const PlaylistItemTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        selected: selected,
        onTap: onTap,
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      );
}
