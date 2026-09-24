import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class PlaybackFeedback extends StatelessWidget {
  const PlaybackFeedback({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.overlay,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ),
      );
}
