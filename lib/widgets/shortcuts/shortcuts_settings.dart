import 'package:flutter/material.dart';

import '../../features/shortcuts/controllers/shortcut_controller.dart';
import '../../core/constants/app_constants.dart';

class ShortcutsSettings extends StatelessWidget {
  const ShortcutsSettings({super.key, required this.controller});

  final ShortcutController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (_, __) => ListView(
          children: controller.values.entries
              .map(
                (entry) => ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  trailing: Text(
                    entry.value,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
              .toList(),
        ),
      );
}
