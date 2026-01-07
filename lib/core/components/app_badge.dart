import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.primary;
    final fg = foregroundColor ?? theme.colorScheme.onPrimary;
    final style =
        textStyle ?? theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700);

    return Container(
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(borderRadius)),
      child: Text(label, style: style),
    );
  }
}
