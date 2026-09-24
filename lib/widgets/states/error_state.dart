import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.onOpenAnother,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenAnother;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 42),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: [
                  if (onRetry != null)
                    OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
                  if (onOpenAnother != null)
                    FilledButton(onPressed: onOpenAnother, child: const Text('Open Another')),
                ],
              ),
            ],
          ),
        ),
      );
}
