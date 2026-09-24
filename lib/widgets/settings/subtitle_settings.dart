import 'package:flutter/material.dart';

class SubtitleSettingsWidget extends StatelessWidget {
  const SubtitleSettingsWidget({super.key, required this.delay, required this.onChanged});

  final Duration delay;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('Subtitle delay'),
        subtitle: Text('${delay.inMilliseconds / 1000}s'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: () => onChanged(delay - const Duration(seconds: 1)), icon: const Icon(Icons.remove)),
            IconButton(onPressed: () => onChanged(delay + const Duration(seconds: 1)), icon: const Icon(Icons.add)),
          ],
        ),
      );
}
