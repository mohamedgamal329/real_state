import 'package:flutter/material.dart';

class BaseGradientPage extends StatelessWidget {
  final Widget child;
  const BaseGradientPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final colorScheme = theme.colorScheme;
    final gradient = isLight
        ? const LinearGradient(
            colors: [Color(0xFFF5F7FB), Color(0xFFEFF2F8), Color(0xFFFFFFFF)],
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
