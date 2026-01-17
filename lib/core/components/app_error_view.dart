import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';

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
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: colors.errorContainer.withValues(alpha: 0.85),
              child: AppSvgIcon(
                AppSVG.error,
                size: 32,
                color: colors.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'something_went_wrong'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'reload'.tr(),
              iconWidget: const AppSvgIcon(AppSVG.refresh),
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
