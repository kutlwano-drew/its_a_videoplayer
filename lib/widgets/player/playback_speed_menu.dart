import 'package:flutter/material.dart';

class PlaybackSpeedMenu extends StatelessWidget {
  const PlaybackSpeedMenu({super.key, required this.onSelected});

  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<double>(
        onSelected: onSelected,
        itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
            .map((e) => PopupMenuItem(value: e, child: Text('${e}x')))
            .toList(),
      );
}
