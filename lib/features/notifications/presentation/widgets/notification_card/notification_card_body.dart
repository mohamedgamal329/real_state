import 'package:flutter/material.dart';

class NotificationCardBody extends StatelessWidget {
  const NotificationCardBody({
    super.key,
    required this.text,
    this.style,
    this.topSpacing = 0,
  });

  final String text;
  final TextStyle? style;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topSpacing > 0) SizedBox(height: topSpacing),
        Text(text, style: style),
      ],
    );
  }
}
