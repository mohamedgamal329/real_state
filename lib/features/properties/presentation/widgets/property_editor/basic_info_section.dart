import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/constants/aed_text.dart';

class PropertyEditorBasicInfoSection extends StatelessWidget {
  const PropertyEditorBasicInfoSection({
    super.key,
    required this.titleCtrl,
    required this.descCtrl,
    required this.priceCtrl,
    required this.titleValidator,
    required this.descValidator,
    required this.priceValidator,
    required this.titleAction,
    required this.descAction,
    required this.priceAction,
  });

  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final FormFieldValidator<String>? titleValidator;
  final FormFieldValidator<String>? descValidator;
  final FormFieldValidator<String>? priceValidator;
  final TextInputAction titleAction;
  final TextInputAction descAction;
  final TextInputAction priceAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'title_label'.tr(),
          controller: titleCtrl,
          validator: titleValidator,
          textInputAction: titleAction,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'description_label'.tr(),
          controller: descCtrl,
          maxLines: 3,
          validator: descValidator,
          textInputAction: descAction,
        ),
        const SizedBox(height: 12),
        AppTextField(
          label: 'price_label'.tr(),
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: priceValidator,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              AED,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'AED',
              ),
            ),
          ),
          textInputAction: priceAction,
        ),
      ],
    );
  }
}
