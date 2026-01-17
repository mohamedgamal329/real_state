import 'package:flutter/material.dart';

class NotificationCardMetaRow extends StatelessWidget {
  const NotificationCardMetaRow({
    super.key,
    required this.label,
    this.leading,
    this.style,
    this.leadingSpacing = 8,
  });

  final String label;
  final Widget? leading;
  final TextStyle? style;
  final double leadingSpacing;

  @override
  Widget build(BuildContext context) {
    if (leading == null) {
      return Text(label, style: style);
    }
    return Row(
      children: [
        leading!,
        SizedBox(width: leadingSpacing),
        Text(label, style: style),
      ],
    );
  }
}
