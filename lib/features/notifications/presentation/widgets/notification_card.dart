import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/utils/time_ago.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/presentation/models/notification_property_summary.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final bool isOwner;
  final bool isTarget;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final NotificationPropertySummary? propertySummary;
  final bool isActionInProgress;
  final bool showActions;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isOwner,
    required this.isTarget,
    this.propertySummary,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.isActionInProgress = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (notification.type) {
      case AppNotificationType.accessRequest:
        return _buildAccessRequest(context);
      case AppNotificationType.propertyAdded:
        return _buildPropertyAdded(context);
      case AppNotificationType.general:
        return _buildGeneral(context);
    }
  }

  Widget _buildAccessRequest(BuildContext context) {
    final status = notification.requestStatus ?? AccessRequestStatus.pending;
    final summary = propertySummary;
    final title = notification.title.isNotEmpty ? notification.title : 'access_request_title'.tr();
    final subtitle = _propertySubtitle(context, summary);
    final typeLabel = _requestTypeLabel();
    final icon = _requestTypeIcon();
    final price = _priceText(summary);
    final timeLabel = timeAgo(notification.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LeadingImage(summary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (price.isNotEmpty)
                    Text(
                      price,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            _buildStatusBadge(status.name, context),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _TypeIcon(icon: icon),
            const SizedBox(width: 8),
            Text(
              typeLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (notification.requesterName != null && notification.requesterName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'access_request_requester'.tr(args: [notification.requesterName!]),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
        if (notification.requestMessage != null && notification.requestMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(notification.requestMessage!, style: Theme.of(context).textTheme.bodyMedium),
        ],
        const SizedBox(height: 12),
        if (status == AccessRequestStatus.pending && isOwner && isTarget && showActions)
          Row(
            children: [
              PrimaryButton(
                label: 'accept'.tr(),
                expand: false,

                radius: 30,
                isLoading: isActionInProgress,
                onPressed: isActionInProgress ? null : onAccept,
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: isActionInProgress ? null : onReject,
                child: Text('reject'.tr()),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          timeLabel,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPropertyAdded(BuildContext context) {
    final summary = propertySummary;
    final fallbackTitle = notification.title == notification.propertyId ? null : notification.title;
    final title = _propertyTitle(context, summary, fallback: fallbackTitle);
    final subtitle = _propertySubtitle(context, summary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LeadingImage(summary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (_priceText(summary).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_priceText(summary)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          timeAgo(notification.createdAt),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (notification.body.isNotEmpty) ...[const SizedBox(height: 6), Text(notification.body)],
      ],
    );
  }

  Widget _buildGeneral(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _TypeIcon(icon: Icons.notifications_none),
            const SizedBox(width: 10),
            Expanded(
              child: Text(notification.title, style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (notification.body.isNotEmpty) Text(notification.body),
        Text(
          timeAgo(notification.createdAt),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, BuildContext context) {
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
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _propertyTitle(
    BuildContext context,
    NotificationPropertySummary? summary, {
    String? fallback,
  }) {
    if (summary == null) return fallback ?? 'property_unavailable'.tr();
    if (summary.isMissing) return 'property_unavailable'.tr();
    if (summary.title.trim().isEmpty) return 'untitled'.tr();
    return summary.title;
  }

  String _propertySubtitle(BuildContext context, NotificationPropertySummary? summary) {
    if (summary == null || summary.isMissing) return '';
    final parts = <String>[];
    if (summary.purposeKey != null) {
      parts.add(summary.purposeKey!.tr());
    }
    if (summary.areaName != null && summary.areaName!.isNotEmpty) {
      parts.add(summary.areaName!);
    }
    return parts.join(' • ');
  }

  String _priceText(NotificationPropertySummary? summary) {
    if (summary == null || summary.isMissing) return '';
    if (summary.price == null) return '';
    return PriceFormatter.format(summary.price!, currency: 'AED');
  }

  String _requestTypeLabel() {
    switch (notification.requestType) {
      case AccessRequestType.phone:
        return 'request_view_phone'.tr();
      case AccessRequestType.images:
        return 'request_view_images'.tr();
      default:
        return 'request_view_location'.tr();
    }
  }

  IconData _requestTypeIcon() {
    switch (notification.requestType) {
      case AccessRequestType.phone:
        return Icons.phone_in_talk_outlined;
      case AccessRequestType.images:
        return Icons.photo_library_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}

class _TypeIcon extends StatelessWidget {
  final IconData icon;
  const _TypeIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: scheme.primary),
    );
  }
}

class _LeadingImage extends StatelessWidget {
  final NotificationPropertySummary? summary;
  const _LeadingImage(this.summary);

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.home_outlined, color: Theme.of(context).colorScheme.primary),
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
