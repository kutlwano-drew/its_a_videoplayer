import 'package:flutter/material.dart';

class PlaybackSettingsWidget extends StatelessWidget {
  const PlaybackSettingsWidget({
    super.key,
    required this.autoPlayNext,
    required this.onChanged,
  });

  final bool autoPlayNext;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
        value: autoPlayNext,
        onChanged: onChanged,
        title: const Text('Auto-play next video'),
      );
}
