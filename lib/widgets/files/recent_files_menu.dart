import 'package:flutter/material.dart';

class RecentFilesMenu extends StatelessWidget {
  const RecentFilesMenu({super.key, required this.files, required this.onSelected});

  final List<String> files;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (_) => files
            .map((file) => PopupMenuItem(value: file, child: Text(file)))
            .toList(),
      );
}
