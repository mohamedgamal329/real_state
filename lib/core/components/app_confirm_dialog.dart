import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum AppConfirmResult { confirmed, cancelled }

class AppConfirmDialog {
  static Future<AppConfirmResult> show(
    BuildContext context, {
    required String titleKey,
    required String descriptionKey,
    String? confirmLabelKey,
    String? cancelLabelKey,
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final theme = Theme.of(context);
    final confirmLabel = (confirmLabelKey ?? 'confirm').tr();
    final cancelLabel = (cancelLabelKey ?? 'cancel').tr();
    final title = titleKey.tr();
    final description = descriptionKey.tr();
    final colorScheme = theme.colorScheme;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    final result = await showDialog<AppConfirmResult>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor),
                ),
              if (icon != null) const SizedBox(width: 12),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          content: Text(description, style: theme.textTheme.bodyMedium),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(AppConfirmResult.cancelled),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    )
                  : null,
              onPressed: () =>
                  Navigator.of(context).pop(AppConfirmResult.confirmed),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );

    return result ?? AppConfirmResult.cancelled;
  }
}
