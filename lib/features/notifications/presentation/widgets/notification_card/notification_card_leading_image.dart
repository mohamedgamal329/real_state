import 'package:flutter/material.dart';
import 'package:real_state/features/notifications/domain/models/notification_property_summary.dart';

class NotificationCardLeadingImage extends StatelessWidget {
  const NotificationCardLeadingImage({super.key, required this.summary});

  final NotificationPropertySummary? summary;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.home_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
    final url = summary?.coverImageUrl;
    if (url == null || url.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
