import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Unified primary action button used across the app for visual consistency.
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool expand;
  final IconData? icon;
  final bool isLoading;
  final double radius;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expand = true,
    this.icon,
    this.isLoading = false,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      colors: [AppColors.primary, Color(0xFF0F8BFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final btn = ElevatedButton.icon(
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
            ),
      onPressed: isLoading ? null : onPressed,
      style:
          ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
            elevation: 3,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
          ).copyWith(
            overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.1)),
            elevation: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed) ? 1.5 : 3,
            ),
          ),
    );

    final decorated = Ink(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(radius)),
      child: btn,
    );

    return AnimatedScale(
      scale: isLoading ? 1.0 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: expand ? SizedBox(width: double.infinity, child: decorated) : decorated,
    );
  }
}
