import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class NoVideoState extends StatelessWidget {
  const NoVideoState({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.video_camera_back_rounded, color: AppColors.textMuted, size: 54),
              const SizedBox(height: 18),
              const Text(
                'No video playing',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Open a video to get started',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.folder_open_rounded, size: 18),
                label: const Text('Open Video'),
              ),
            ],
          ),
        ),
      );
}
