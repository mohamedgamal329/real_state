import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/primary_button.dart';

class NotificationCardActions extends StatelessWidget {
  const NotificationCardActions({
    super.key,
    required this.notificationId,
    required this.showActionButtons,
    required this.isActionDisabled,
    required this.showInlineLoader,
    required this.acceptLoading,
    required this.rejectLoading,
    this.onAccept,
    this.onReject,
  });

  final String notificationId;
  final bool showActionButtons;
  final bool isActionDisabled;
  final bool showInlineLoader;
  final bool acceptLoading;
  final bool rejectLoading;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showInlineLoader) ...[
          const SizedBox(height: 6),
          const SizedBox(height: 2, child: LinearProgressIndicator()),
        ],
        if (showActionButtons) ...[
          Row(
            children: [
              PrimaryButton(
                key: ValueKey('notification_accept_$notificationId'),
                label: 'accept'.tr(),
                expand: false,
                radius: 30,
                isLoading: acceptLoading,
                onPressed: isActionDisabled ? null : onAccept,
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                key: ValueKey('notification_reject_$notificationId'),
                onPressed: isActionDisabled ? null : onReject,
                child: SizedBox(
                  height: 18,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: rejectLoading ? 0 : 1,
                        child: Text('reject'.tr()),
                      ),
                      if (rejectLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ] else
          const SizedBox(height: 8),
      ],
    );
  }
}
