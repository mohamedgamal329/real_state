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
    return Skeletonizer(
      enabled: enabled,
      effect: const ShimmerEffect(duration: Duration(milliseconds: 1100)),
      child: AbsorbPointer(
        absorbing: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 0.65 : 1,
          child: child,
        ),
      ),
    );
  }
}
