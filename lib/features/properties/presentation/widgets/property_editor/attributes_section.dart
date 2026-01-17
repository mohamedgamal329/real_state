import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';

class PropertyEditorAttributesSection extends StatelessWidget {
  const PropertyEditorAttributesSection({
    super.key,
    required this.roomsCtrl,
    required this.kitchensCtrl,
    required this.floorsCtrl,
  });

  final TextEditingController roomsCtrl;
  final TextEditingController kitchensCtrl;
  final TextEditingController floorsCtrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            label: 'rooms_label_simple'.tr(),
            controller: roomsCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            label: 'kitchens_label'.tr(),
            controller: kitchensCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            label: 'floors_label_simple'.tr(),
            controller: floorsCtrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
          ),
        ),
      ],
    );
  }
}
