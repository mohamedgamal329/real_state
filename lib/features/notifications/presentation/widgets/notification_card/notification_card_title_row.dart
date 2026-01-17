import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_spacing.dart';

class NotificationCardTitleRow extends StatelessWidget {
  const NotificationCardTitleRow({
    super.key,
    required this.title,
    required this.isUnread,
  });

  final String title;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (isUnread) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
