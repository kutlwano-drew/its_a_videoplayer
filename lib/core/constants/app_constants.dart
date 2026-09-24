import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF0B0B0D);
  static const videoBackground = Color(0xFF050506);
  static const surface = Color(0xFF151518);
  static const surfaceElevated = Color(0xFF1D1D21);
  static const border = Color(0xFF29292E);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const accent = Color(0xFFFFFFFF);
  static const overlay = Color(0x99000000);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
}

abstract final class AppConstants {
  static const appName = "It's a Video Player";
  static const defaultVolume = 0.50;
  static const defaultSpeed = 1.0;
  static const seekSeconds = 10;
  static const controlHideDelaySeconds = 10;
  static const continueThresholdSeconds = 30;
  static const continuePromptSeconds = 30;
  static const playlistWidth = 320.0;
  static const volumeWheelStep = 0.10;
  static const trickSpeeds = <double>[2.0, 4.0, 16.0];
}
