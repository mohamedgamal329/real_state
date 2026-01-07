import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/features/splash/presentation/widgets/splash_logo.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? description;
  final String? actionLabel;
  final IconData icon;
  final VoidCallback? action;

  const EmptyStateWidget({
    super.key,
    this.description,
    this.actionLabel,
    this.icon = Icons.inbox_rounded,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(width: 90, height: 90),

            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: action,
                child: Text(actionLabel?.tr() ?? 'reload'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
