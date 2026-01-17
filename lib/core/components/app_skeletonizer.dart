import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Shared wrapper for skeleton loading to keep layout identical while disabling interactions.
class AppSkeletonizer extends StatelessWidget {
  final bool enabled;
  final Widget child;

  const AppSkeletonizer({
    super.key,
    required this.enabled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    return Skeletonizer(
      enabled: enabled,
      effect: ShimmerEffect(
        duration: const Duration(milliseconds: 1200),
        baseColor: isLight
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.9)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        highlightColor: isLight
            ? Colors.white
            : scheme.surface.withValues(alpha: 0.6),
      ),
      child: AbsorbPointer(
        absorbing: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 0.7 : 1,
          child: child,
        ),
      ),
    );
  }
}
