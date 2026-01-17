import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'pressable_scale.dart';

/// Unified primary action button used across the app for visual consistency.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool expand;
  final IconData? icon;
  final Widget? iconWidget;
  final bool isLoading;
  final double radius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.icon,
    this.iconWidget,
    this.isLoading = false,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;
    final gradient = LinearGradient(
      colors: isEnabled
          ? const [AppColors.primary, Color(0xFF0F8BFF)]
          : [
              AppColors.primary.withValues(alpha: 0.55),
              const Color(0xFF0F8BFF).withValues(alpha: 0.55),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final btn = ElevatedButton.icon(
      icon:
          iconWidget ??
          (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
      label: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
      onPressed: isLoading ? null : onPressed,
      style:
          ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              Colors.white.withValues(alpha: 0.1),
            ),
            elevation: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed) ? 1.5 : 3,
            ),
          ),
    );

    final decorated = Ink(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(
              alpha: isDark ? 0.22 : (isEnabled ? 0.28 : 0.12),
            ),
            blurRadius: isDark ? 16 : 22,
            spreadRadius: isEnabled ? 0.6 : 0,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: btn,
    );

    return PressableScale(
      enabled: onPressed != null && !isLoading,
      scale: 0.98,
      hoverScale: 0.99,
      child: expand
          ? SizedBox(width: double.infinity, child: decorated)
          : decorated,
    );
  }
}
