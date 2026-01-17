import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_spacing.dart';

class LoadingDialog {
  static Future<T> show<T>(BuildContext context, Future<T> future) async {
    if (!context.mounted) return await future;
    final navigator = Navigator.of(context);
    if (!navigator.mounted) return await future;

    // Unfocus to avoid focus-related crashes during route transition
    FocusScope.of(context).unfocus();

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (c) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(c).size.width * 0.28,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxl,
              horizontal: AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 54,
                  width: 54,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 3,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'loading'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'please_wait'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      return await future;
    } finally {
      if (navigator.mounted && navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}
