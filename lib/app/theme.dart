import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      surface: AppColors.surface,
      primary: AppColors.accent,
      secondary: AppColors.textSecondary,
      error: AppColors.danger,
    ),
    useMaterial3: true,
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 450),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surfaceElevated,
      textStyle: TextStyle(color: AppColors.textPrimary),
    ),
  );
}
