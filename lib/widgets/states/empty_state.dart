import 'package:flutter/material.dart';

import '../common/section_header.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(title: title),
            const SizedBox(height: 6),
            Text(message),
          ],
        ),
      );
}
