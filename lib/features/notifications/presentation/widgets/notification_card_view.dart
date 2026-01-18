import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/core/utils/time_ago.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/models/notification_property_summary.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_actions.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_body.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_leading_image.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_meta_row.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_status_badge.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_title_row.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card/notification_card_type_icon.dart';

class NotificationCardView extends StatelessWidget {
  const NotificationCardView({
    super.key,
    required this.viewModel,
    required this.isOwner,
    required this.isTarget,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = true,
    this.actionStatus = NotificationActionStatus.idle,
  });

  final NotificationViewModel viewModel;
  final bool isOwner;
  final bool isTarget;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;
  final NotificationActionStatus actionStatus;

  bool get _isBusy => actionStatus != NotificationActionStatus.idle;

  bool get _showInlineLoader =>
      actionStatus == NotificationActionStatus.accepting ||
      actionStatus == NotificationActionStatus.rejecting;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    return Card(
      key: ValueKey('notification_card_${viewModel.notification.id}'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  decoration: BoxDecoration(
                    color: viewModel.isUnread
                        ? accentColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (viewModel.notification.type) {
      case AppNotificationType.accessRequest:
        return _buildAccessRequest(context);
      case AppNotificationType.propertyAdded:
        return _buildPropertyAdded(context);
      case AppNotificationType.general:
        return _buildGeneral(context);
    }
  }

  Widget _buildAccessRequest(BuildContext context) {
    final notification = viewModel.notification;
    final status = notification.requestStatus ?? AccessRequestStatus.pending;
    final summary = viewModel.propertySummary;
    final title = notification.title.isNotEmpty
        ? notification.title
        : 'access_request_title'.tr();
    final subtitle = _propertySubtitle(context, summary);
    final typeLabel = _requestTypeLabel();
    final icon = _requestTypeIcon();
    final price = _priceText(summary);
    final timeLabel = timeAgo(notification.createdAt);
    final showActionButtons =
        status == AccessRequestStatus.pending && isTarget && showActions;
    final isActionDisabled = _isBusy;
    final rejectLoading = actionStatus == NotificationActionStatus.rejecting;
    final acceptLoading = actionStatus == NotificationActionStatus.accepting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            NotificationCardLeadingImage(summary: summary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationCardTitleRow(
                    title: title,
                    isUnread: viewModel.isUnread,
                  ),
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
            NotificationCardStatusBadge(status: status.name),
          ],
        ),
        const SizedBox(height: 8),
        NotificationCardMetaRow(
          leading: NotificationCardTypeIcon(icon: icon),
          label: typeLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (notification.requesterName != null &&
            notification.requesterName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          NotificationCardMetaRow(
            label: 'access_request_requester'.tr(
              args: [notification.requesterName!],
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        NotificationCardBody(
          text: notification.requestMessage ?? '',
          topSpacing: 8,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        NotificationCardActions(
          notificationId: notification.id,
          showActionButtons: showActionButtons,
          isActionDisabled: isActionDisabled,
          showInlineLoader: _showInlineLoader,
          acceptLoading: acceptLoading,
          rejectLoading: rejectLoading,
          onAccept: onAccept,
          onReject: onReject,
        ),
        NotificationCardMetaRow(
          label: timeLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyAdded(BuildContext context) {
    final notification = viewModel.notification;
    final summary = viewModel.propertySummary;
    final fallbackTitle = notification.title == notification.propertyId
        ? null
        : notification.title;
    final title = _propertyTitle(context, summary, fallback: fallbackTitle);
    final subtitle = _propertySubtitle(context, summary);
    final timeLabel = timeAgo(notification.createdAt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationCardLeadingImage(summary: summary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NotificationCardTitleRow(
                    title: title,
                    isUnread: viewModel.isUnread,
                  ),
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
        NotificationCardMetaRow(
          label: timeLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        NotificationCardBody(text: viewModel.notification.body, topSpacing: 6),
      ],
    );
  }

  Widget _buildGeneral(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const NotificationCardTypeIcon(icon: Icons.notifications_none),
            const SizedBox(width: 10),
            Expanded(
              child: NotificationCardTitleRow(
                title: viewModel.notification.title,
                isUnread: viewModel.isUnread,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        NotificationCardBody(text: viewModel.notification.body),
        NotificationCardMetaRow(
          label: timeAgo(viewModel.notification.createdAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
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

  String _propertySubtitle(
    BuildContext context,
    NotificationPropertySummary? summary,
  ) {
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
    switch (viewModel.notification.requestType) {
      case AccessRequestType.phone:
        return 'request_view_phone'.tr();
      case AccessRequestType.images:
        return 'request_view_images'.tr();
      default:
        return 'request_view_location'.tr();
    }
  }

  IconData _requestTypeIcon() {
    switch (viewModel.notification.requestType) {
      case AccessRequestType.phone:
        return Icons.phone_in_talk_outlined;
      case AccessRequestType.images:
        return Icons.photo_library_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }
}
