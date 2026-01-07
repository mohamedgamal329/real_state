import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/location/presentation/widgets/location_picker_form_field.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

import '../models/property_editor_models.dart';
import 'property_images_editor.dart';

class PropertyEditorForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController locationUrlCtrl;
  final TextEditingController roomsCtrl;
  final TextEditingController kitchensCtrl;
  final TextEditingController floorsCtrl;
  final TextEditingController phoneCtrl;
  final bool isEditing;
  final bool showSkeleton;
  final bool hasPool;
  final bool isImagesHidden;
  final PropertyPurpose purpose;
  final String? locationId;
  final List<LocationArea> locations;
  final List<EditableImage> images;
  final VoidCallback onSave;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onSetCover;
  final ValueChanged<bool> onTogglePool;
  final ValueChanged<bool> onToggleImagesHidden;
  final ValueChanged<String?> onLocationChanged;
  final VoidCallback onAddLocation;
  final ValueChanged<PropertyPurpose> onPurposeChanged;

  const PropertyEditorForm({
    super.key,
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.priceCtrl,
    required this.locationUrlCtrl,
    required this.roomsCtrl,
    required this.kitchensCtrl,
    required this.floorsCtrl,
    required this.phoneCtrl,
    required this.isEditing,
    required this.showSkeleton,
    required this.hasPool,
    required this.isImagesHidden,
    required this.purpose,
    required this.locationId,
    required this.locations,
    required this.images,
    required this.onSave,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSetCover,
    required this.onTogglePool,
    required this.onToggleImagesHidden,
    required this.onLocationChanged,
    required this.onAddLocation,
    required this.onPurposeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: showSkeleton,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'details'.tr(),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'title_label'.tr(),
                      controller: titleCtrl,
                      validator: (v) => Validators.isNotEmpty(v) ? null : 'title_required'.tr(),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'description_label'.tr(),
                      controller: descCtrl,
                      maxLines: 3,
                      validator: (v) =>
                          Validators.isNotEmpty(v) ? null : 'description_required'.tr(),
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'price_label'.tr(),
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (!Validators.isNotEmpty(v)) return 'price_required'.tr();
                        return Validators.isValidPrice(v) ? null : 'price_invalid'.tr();
                      },
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
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'location_url'.tr(),
                      controller: locationUrlCtrl,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.isValidUrl(v) ? null : 'location_url_invalid'.tr();
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PropertyPurpose>(
                      initialValue: purpose,
                      items: PropertyPurpose.values
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text('purpose.${p.name}'.tr().toUpperCase()),
                            ),
                          )
                          .toList(),
                      validator: (p) => Validators.isSelected(p) ? null : 'purpose_required'.tr(),
                      onChanged: (p) {
                        if (p != null) onPurposeChanged(p);
                      },
                      decoration: InputDecoration(labelText: 'purpose_label'.tr()),
                    ),
                    const SizedBox(height: 12),
                    LocationPickerFormField(
                      value: locationId,
                      locations: locations,
                      onChanged: onLocationChanged,
                      onAddPressed: onAddLocation,
                      validator: (v) => Validators.isSelected(v) ? null : 'location_required'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildCountsRow(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'settings'.tr(),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'owner_phone_optional'.tr(),
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.isValidPhone(v) ? null : 'owner_phone_invalid'.tr();
                      },
                      textInputAction: TextInputAction.done,
                    ),
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
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'images'.tr(),
                child: PropertyImagesEditor(
                  images: images,
                  onPickImages: onPickImages,
                  onRemove: onRemoveImage,
                  onSetCover: onSetCover,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              PrimaryButton(
                label: isEditing ? 'update'.tr() : 'create'.tr(),
                icon: Icons.save,
                onPressed: onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Row _buildCountsRow() {
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
