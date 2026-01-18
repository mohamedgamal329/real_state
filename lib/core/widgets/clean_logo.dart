import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_images.dart';

class CleanLogo extends StatelessWidget {
  final double size;
  const CleanLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // In light mode, show image directly without container decoration
    // to avoid any border/shadow artifacts
    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        AppImages.logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );

    if (!isDark) {
      // FIX 7: Add subtle border in light mode so logo doesn't blend into white backgrounds
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: imageWidget,
      );
    }

    // Dark mode: wrap in container with white background
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: imageWidget,
    );
  }
}
