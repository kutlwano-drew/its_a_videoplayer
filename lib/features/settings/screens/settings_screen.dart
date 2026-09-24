import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text(
          'Settings are intentionally lightweight in v1.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
