import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../core/constants/app_constants.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => LoadingAnimationWidget.staggeredDotsWave(
        color: AppColors.textPrimary,
        size: size,
      );
}
