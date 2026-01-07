import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/presentation/cubit/access_request_action_cubit.dart';
import 'package:real_state/features/notifications/presentation/cubit/access_request_action_state.dart';
import 'package:real_state/features/notifications/presentation/models/notification_property_summary.dart';
import 'package:real_state/features/models/entities/access_request.dart';

class AccessRequestDialog extends StatelessWidget {
  final AppNotification notification;
  final NotificationPropertySummary propertySummary;
  final String requesterName;
  final VoidCallback? onCompleted;

  const AccessRequestDialog({
    super.key,
    required this.notification,
    required this.propertySummary,
    required this.requesterName,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccessRequestActionCubit, AccessRequestActionState>(
      listener: (context, state) async {
        if (state is AccessRequestActionSuccess) {
          Navigator.of(context, rootNavigator: true).maybePop();
          onCompleted?.call();
        } else if (state is AccessRequestActionFailure) {
          AppSnackbar.show(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        final isBusy = state is AccessRequestActionInProgress;
        return PopScope(
          canPop: !isBusy,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'access_request_title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requesterName.isNotEmpty
                      ? 'access_request_requester'.tr(args: [requesterName])
                      : 'access_request_unknown_requester'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _TypeBadge(type: notification.requestType),
                if (notification.requestMessage != null &&
                    notification.requestMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'access_request_message_label'.tr(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.requestMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'access_request_property_label'.tr(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _PropertySummaryCard(summary: propertySummary),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        final cubit = context.read<AccessRequestActionCubit>();
                        final error = await LoadingDialog.show<String?>(
                          context,
                          cubit.reject(
                            notificationId: notification.id,
                            requestId: notification.requestId!,
                            targetUserId: notification.targetUserId,
                          ),
                        );
                        if (error != null) {
                          AppSnackbar.show(context, error, isError: true);
                        }
                      },
                child: Text('reject'.tr()),
              ),
              FilledButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        final cubit = context.read<AccessRequestActionCubit>();
                        final error = await LoadingDialog.show<String?>(
                          context,
                          cubit.accept(
                            notificationId: notification.id,
                            requestId: notification.requestId!,
                            targetUserId: notification.targetUserId,
                          ),
                        );
                        if (error != null) {
                          AppSnackbar.show(context, error, isError: true);
                        }
                      },
                child: Text('accept'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PropertySummaryCard extends StatelessWidget {
  final NotificationPropertySummary summary;
  const _PropertySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (!summary.isMissing) {
      if (summary.purposeKey != null && summary.purposeKey!.isNotEmpty) {
        subtitleParts.add(summary.purposeKey!.tr());
      }
      if (summary.areaName != null && summary.areaName!.isNotEmpty) {
        subtitleParts.add(summary.areaName!);
      } else {
        subtitleParts.add('area_unavailable'.tr());
      }
    }
    final subtitle = subtitleParts.join(' • ');
    final priceText = summary.price != null
        ? PriceFormatter.format(summary.price!, currency: '').trim()
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.isMissing
                ? 'property_unavailable'.tr()
                : (summary.title.isEmpty ? 'untitled'.tr() : summary.title),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (priceText != null && priceText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '$priceText $AED',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'AED',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final AccessRequestType? type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      AccessRequestType.phone => 'access_request_type_phone'.tr(),
      AccessRequestType.images => 'access_request_type_images'.tr(),
      _ => 'access_request_type_location'.tr(),
    };
    final icon = switch (type) {
      AccessRequestType.phone => Icons.phone_in_talk_outlined,
      AccessRequestType.images => Icons.photo_library_outlined,
      _ => Icons.location_on_outlined,
    };
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
