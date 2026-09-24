import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class PlaylistEmptyState extends StatelessWidget {
  const PlaylistEmptyState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.playlist_add_rounded, color: AppColors.textMuted, size: 46),
              const SizedBox(height: 12),
              const Text(
                'Select videos to build your playlist',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can add several videos at once and arrange them later.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.video_library_outlined, size: 18),
                label: const Text('Select Videos'),
              ),
            ],
          ),
        ),
      );
}
