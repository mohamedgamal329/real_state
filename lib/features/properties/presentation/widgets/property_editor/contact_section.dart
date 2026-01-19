import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/constants/app_spacing.dart';

class PropertyEditorContactSection extends StatelessWidget {
  const PropertyEditorContactSection({
    super.key,
    required this.phoneCtrl,
    required this.securityNumberCtrl,
    required this.hasPool,
    required this.isImagesHidden,
    required this.onTogglePool,
    required this.onToggleImagesHidden,
    required this.phoneValidator,
    required this.showSecurityNumber,
    required this.onShowSecurityNumber,
  });

  final TextEditingController phoneCtrl;
  final TextEditingController securityNumberCtrl;
  final bool hasPool;
  final bool isImagesHidden;
  final ValueChanged<bool> onTogglePool;
  final ValueChanged<bool> onToggleImagesHidden;
  final FormFieldValidator<String>? phoneValidator;
  final bool showSecurityNumber;
  final VoidCallback onShowSecurityNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'owner_phone_optional'.tr(),
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          validator: phoneValidator,
          textInputAction: TextInputAction.done,
        ),
        // Only securityNumber is now shown in UI.
        if (!showSecurityNumber)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onShowSecurityNumber,
              child: Text('add_security_number'.tr()),
            ),
          ),
        if (showSecurityNumber) ...[
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'security_number_optional'.tr(),
            controller: securityNumberCtrl,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
        ],
        SwitchListTile(
          title: Text('has_pool_switch'.tr()),
          value: hasPool,
          onChanged: onTogglePool,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: Text('hide_images_default'.tr()),
          value: isImagesHidden,
          onChanged: onToggleImagesHidden,
          dense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
