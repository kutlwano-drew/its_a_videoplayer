import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/duration_utils.dart';
import '../../features/ab_loop/controllers/ab_loop_controller.dart';

class ABLoopIndicator extends StatelessWidget {
  const ABLoopIndicator({super.key, required this.controller});

  final ABLoopController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.active) return const SizedBox.shrink();
    return Text(
      '${formatDuration(controller.a!)} → ${formatDuration(controller.b!)}',
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    );
  }
}
