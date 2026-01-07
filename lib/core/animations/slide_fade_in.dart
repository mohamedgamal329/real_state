import 'package:flutter/material.dart';

/// Small slide + fade-in wrapper for list items.
class SlideFadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double offsetY;
  final Duration? delay;

  const SlideFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.offsetY = 12,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,

      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
