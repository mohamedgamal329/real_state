import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_colors.dart';

class BaseGradientPage extends StatelessWidget {
  final Widget child;
  const BaseGradientPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;
    final gradient = isLight
        ? LinearGradient(
            colors: [
              const Color(0xFFEEF3FF).withValues(alpha: 0.7),
              AppColors.background.withValues(alpha: 0.85),
              AppColors.surface.withValues(alpha: 0.9),
              const Color(0xFFFCFDFF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          )
        : LinearGradient(
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
              colorScheme.surface.withValues(alpha: 0.9),
              colorScheme.surface.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(top: false, child: child),
    );
  }
}
