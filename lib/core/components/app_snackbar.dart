import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';

enum AppSnackbarType { success, warning, error }

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    AppSnackbarType type = AppSnackbarType.success,
    Duration duration = const Duration(milliseconds: 3200),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = _backgroundColor(context, type, colorScheme);
    final icon = _iconFor(type);
    final fg = _foregroundColor(type, colorScheme);
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bgColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      content: Row(
        children: [
          IconTheme(
            data: IconThemeData(color: fg),
            child: icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      duration: duration,
      elevation: 3,
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: fg,
              onPressed: onAction,
            )
          : null,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Color _backgroundColor(
    BuildContext context,
    AppSnackbarType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case AppSnackbarType.warning:
        return colorScheme.tertiaryContainer;
      case AppSnackbarType.error:
        return colorScheme.errorContainer;
      case AppSnackbarType.success:
        return colorScheme.primaryContainer;
    }
  }

  static Color _foregroundColor(AppSnackbarType type, ColorScheme colorScheme) {
    switch (type) {
      case AppSnackbarType.warning:
        return colorScheme.onTertiaryContainer;
      case AppSnackbarType.error:
        return colorScheme.onErrorContainer;
      case AppSnackbarType.success:
        return colorScheme.onPrimaryContainer;
    }
  }

  static Widget _iconFor(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.warning:
        return const AppSvgIcon(AppSVG.warning);
      case AppSnackbarType.error:
        return const AppSvgIcon(AppSVG.error);
      case AppSnackbarType.success:
        return const AppSvgIcon(AppSVG.success);
    }
  }
}
