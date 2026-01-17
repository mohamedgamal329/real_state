import 'package:flutter/material.dart';

class NotificationCardTypeIcon extends StatelessWidget {
  const NotificationCardTypeIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(76),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: scheme.primary),
    );
  }
}
