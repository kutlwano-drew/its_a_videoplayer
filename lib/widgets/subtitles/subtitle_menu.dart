import 'package:flutter/material.dart';

class SubtitleMenu extends StatelessWidget {
  const SubtitleMenu({super.key, required this.onDelayChanged});

  final ValueChanged<Duration> onDelayChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Duration>(
        onSelected: onDelayChanged,
        itemBuilder: (_) => const [
          PopupMenuItem(value: Duration(seconds: -5), child: Text('Subtitle -5s')),
          PopupMenuItem(value: Duration.zero, child: Text('Subtitle 0s')),
          PopupMenuItem(value: Duration(seconds: 5), child: Text('Subtitle +5s')),
        ],
      );
}
