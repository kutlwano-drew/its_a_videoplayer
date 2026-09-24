import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../core/constants/app_constants.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading video…'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: AppColors.textPrimary,
              size: 42,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}
