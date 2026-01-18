import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyPhoneSection extends StatelessWidget {
  final bool phoneVisible;
  final String? phoneText;
  final VoidCallback? onRequestAccess;
  final String? keyPrefix;
  final String icon;
  final bool showCallButton;
  final String? hiddenLabelKey;

  const PropertyPhoneSection({
    super.key,
    required this.phoneVisible,
    required this.phoneText,
    this.onRequestAccess,
    this.keyPrefix,
    this.icon = AppSVG.phone,
    this.showCallButton = true,
    this.hiddenLabelKey,
  });

  static const ValueKey<String> hiddenPhoneKey = ValueKey(
    'property_phone_hidden_card',
  );
  static const ValueKey<String> hiddenPhoneLabelKey = ValueKey(
    'property_phone_hidden',
  );
  static const ValueKey<String> requestButtonKey = ValueKey(
    'property_phone_request_button',
  );

  ValueKey<String> get _hiddenPhoneKey {
    if (keyPrefix == null || keyPrefix!.isEmpty) return hiddenPhoneKey;
    return ValueKey('property_phone_hidden_card_${keyPrefix!}');
  }

  ValueKey<String> get _hiddenPhoneLabelKey {
    if (keyPrefix == null || keyPrefix!.isEmpty) return hiddenPhoneLabelKey;
    return ValueKey('property_phone_hidden_${keyPrefix!}');
  }

  ValueKey<String> get _requestButtonKey {
    if (keyPrefix == null || keyPrefix!.isEmpty) return requestButtonKey;
    return ValueKey('property_phone_request_button_${keyPrefix!}');
  }

  @override
  Widget build(BuildContext context) {
    final phoneNumber = phoneText;
    final canCall =
        phoneVisible &&
        phoneNumber != null &&
        phoneNumber.isNotEmpty &&
        showCallButton;

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
            AppSvgIcon(icon, size: 20),
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
                icon: const AppSvgIcon(AppSVG.phone),
                label: Text('call_owner'.tr()),
              ),
          ],
        ),
      );
    }

    return Card(
      key: _hiddenPhoneKey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const AppSvgIcon(AppSVG.lock, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                (hiddenLabelKey ?? 'phone_hidden').tr(),
                key: _hiddenPhoneLabelKey,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (onRequestAccess != null)
              PrimaryButton(
                key: _requestButtonKey,
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
        AppSnackbar.show(
          context,
          'something_went_wrong'.tr(),
          type: AppSnackbarType.error,
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          'something_went_wrong'.tr(),
          type: AppSnackbarType.error,
        );
      }
    }
  }
}
