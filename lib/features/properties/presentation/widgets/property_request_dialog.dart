import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyRequestDialog {
  PropertyRequestDialog._();

  static Future<String?> show(
    BuildContext context,
    AccessRequestType type, {
    Property? property,
    String? areaName,
  }) {
    final controller = TextEditingController();
    final titleKey = switch (type) {
      AccessRequestType.images => 'request_images_access',
      AccessRequestType.phone => 'request_phone_access',
      AccessRequestType.location => 'request_location_access',
    };
    return showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titleKey.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property != null) ...[
              Text(
                property.title ?? 'untitled'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              if (areaName?.isNotEmpty == true)
                Text(areaName!, style: Theme.of(context).textTheme.bodySmall),
              if (property.price != null) ...[
                const SizedBox(height: 4),
                Text(
                  PriceFormatter.format(property.price!, currency: AED),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AED',
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
            AppTextField(
              hintText: 'optional_message'.tr(),
              controller: controller,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => c.pop(), child: Text('cancel'.tr())),
          PrimaryButton(
            label: 'submit'.tr(),
            expand: false,
            onPressed: () => c.pop(controller.text.trim()),
          ),
        ],
      ),
    );
  }
}
