import 'package:flutter/material.dart';

class AppContextMenu extends StatelessWidget {
  const AppContextMenu({super.key, required this.items});

  final List<PopupMenuEntry<String>> items;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        itemBuilder: (_) => items,
      );
}
