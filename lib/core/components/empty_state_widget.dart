import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/features/splash/presentation/widgets/splash_logo.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? description;
  final String? actionLabel;
  final IconData? icon;
  final String? svgAsset;
  final Widget? leadingIcon;
  final VoidCallback? action;

  const EmptyStateWidget({
    super.key,
    this.description,
    this.actionLabel,
    this.icon,
    this.svgAsset,
    this.leadingIcon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(width: 90, height: 90),

            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
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
