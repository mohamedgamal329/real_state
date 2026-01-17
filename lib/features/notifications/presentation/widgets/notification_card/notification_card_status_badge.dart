import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationCardStatusBadge extends StatelessWidget {
  const NotificationCardStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color color;
    switch (status) {
      case 'accepted':
        color = colors.primary;
        break;
      case 'rejected':
        color = colors.error;
        break;
      case 'expired':
        color = colors.outline;
        break;
      default:
        color = colors.secondary;
    }
    final label = 'access_request_status_$status'.tr();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
