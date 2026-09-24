import 'package:flutter/material.dart';

import '../shortcuts/shortcuts_settings.dart';
import '../../features/shortcuts/controllers/shortcut_controller.dart';

class ShortcutSettingsWidget extends StatelessWidget {
  const ShortcutSettingsWidget({super.key, required this.controller});

  final ShortcutController controller;

  @override
  Widget build(BuildContext context) => ShortcutsSettings(controller: controller);
}
