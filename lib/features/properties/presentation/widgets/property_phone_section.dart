import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyPhoneSection extends StatelessWidget {
  final bool phoneVisible;
  final String? phoneText;
  final VoidCallback? onRequestAccess;

  const PropertyPhoneSection({
    super.key,
    required this.phoneVisible,
    required this.phoneText,
    this.onRequestAccess,
  });

  @override
  Widget build(BuildContext context) {
    final phoneNumber = phoneText;
    final canCall =
        phoneVisible && phoneNumber != null && phoneNumber.isNotEmpty;

    if (phoneVisible) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone_iphone, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                phoneNumber ?? 'no_phone_available'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (canCall)
              FilledButton.icon(
                onPressed: () => _callOwner(context, phoneNumber),
                icon: const Icon(Icons.call),
                label: Text('call_owner'.tr()),
              ),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'phone_hidden'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (onRequestAccess != null)
              PrimaryButton(
                label: 'request_phone_access'.tr(),
                expand: false,
                onPressed: onRequestAccess,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _callOwner(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackbar.show(context, 'something_went_wrong'.tr(), isError: true);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(context, 'something_went_wrong'.tr(), isError: true);
      }
    }
  }
}
