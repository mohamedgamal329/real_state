import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/primary_button.dart';

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AppErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colors.errorContainer,
              child: Icon(
                Icons.error_outline,
                size: 32,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'something_went_wrong'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'reload'.tr(),
              icon: Icons.refresh,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
