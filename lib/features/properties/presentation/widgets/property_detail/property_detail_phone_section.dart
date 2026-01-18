import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/properties/presentation/widgets/property_phone_section.dart';

class PropertyDetailPhoneSection extends StatelessWidget {
  const PropertyDetailPhoneSection({
    super.key,
    this.labelKey = 'owner_phone',
    required this.phoneVisible,
    required this.phoneText,
    required this.onRequestAccess,
    this.keyPrefix,
    this.icon = AppSVG.phone,
    this.showCallButton = true,
    this.hiddenLabelKey,
  });

  final String labelKey;
  final bool phoneVisible;
  final String? phoneText;
  final VoidCallback? onRequestAccess;
  final String? keyPrefix;
  final String icon;
  final bool showCallButton;
  final String? hiddenLabelKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelKey.tr(), style: textTheme.titleMedium),
        const SizedBox(height: 8),
        PropertyPhoneSection(
          phoneVisible: phoneVisible,
          phoneText: phoneText,
          onRequestAccess: onRequestAccess,
          keyPrefix: keyPrefix,
          icon: icon,
          showCallButton: showCallButton,
          hiddenLabelKey: hiddenLabelKey,
        ),
      ],
    );
  }
}
