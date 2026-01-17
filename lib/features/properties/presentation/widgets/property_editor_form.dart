import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

import 'package:real_state/features/properties/models/property_editor_models.dart';
import 'property_editor/attributes_section.dart';
import 'property_editor/basic_info_section.dart';
import 'property_editor/contact_section.dart';
import 'property_editor/images_section.dart';
import 'property_editor/location_section.dart';

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
  final TextEditingController securityGuardPhoneCtrl;
  final bool isEditing;
  final bool showSkeleton;
  final bool hasPool;
  final bool isImagesHidden;
  final bool showSecurityGuardPhone;
  final VoidCallback onShowSecurityGuardPhone;
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
    required this.securityGuardPhoneCtrl,
    required this.isEditing,
    required this.showSkeleton,
    required this.hasPool,
    required this.isImagesHidden,
    required this.showSecurityGuardPhone,
    required this.onShowSecurityGuardPhone,
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
                    PropertyEditorBasicInfoSection(
                      titleCtrl: titleCtrl,
                      descCtrl: descCtrl,
                      priceCtrl: priceCtrl,
                      titleValidator: (v) => Validators.isNotEmpty(v)
                          ? null
                          : 'title_required'.tr(),
                      descValidator: (v) => Validators.isNotEmpty(v)
                          ? null
                          : 'description_required'.tr(),
                      priceValidator: (v) {
                        if (!Validators.isNotEmpty(v))
                          return 'price_required'.tr();
                        return Validators.isValidPrice(v)
                            ? null
                            : 'price_invalid'.tr();
                      },
                      titleAction: TextInputAction.next,
                      descAction: TextInputAction.newline,
                      priceAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    PropertyEditorLocationSection(
                      locationUrlCtrl: locationUrlCtrl,
                      purpose: purpose,
                      locationId: locationId,
                      locations: locations,
                      onPurposeChanged: onPurposeChanged,
                      onLocationChanged: onLocationChanged,
                      onAddLocation: onAddLocation,
                      locationUrlValidator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.isValidUrl(v)
                            ? null
                            : 'location_url_invalid'.tr();
                      },
                      purposeValidator: (p) => Validators.isSelected(p)
                          ? null
                          : 'purpose_required'.tr(),
                      locationValidator: (v) => Validators.isSelected(v)
                          ? null
                          : 'location_required'.tr(),
                    ),
                    const SizedBox(height: 12),
                    PropertyEditorAttributesSection(
                      roomsCtrl: roomsCtrl,
                      kitchensCtrl: kitchensCtrl,
                      floorsCtrl: floorsCtrl,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'settings'.tr(),
                child: PropertyEditorContactSection(
                  phoneCtrl: phoneCtrl,
                  securityGuardPhoneCtrl: securityGuardPhoneCtrl,
                  hasPool: hasPool,
                  isImagesHidden: isImagesHidden,
                  onTogglePool: onTogglePool,
                  onToggleImagesHidden: onToggleImagesHidden,
                  showSecurityGuardPhone: showSecurityGuardPhone,
                  onShowSecurityGuardPhone: onShowSecurityGuardPhone,
                  phoneValidator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return Validators.isValidPhone(v)
                        ? null
                        : 'owner_phone_invalid'.tr();
                  },
                  securityGuardPhoneValidator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    return Validators.isValidPhone(v)
                        ? null
                        : 'owner_phone_invalid'.tr();
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'images'.tr(),
                child: PropertyEditorImagesSection(
                  images: images,
                  onPickImages: onPickImages,
                  onRemoveImage: onRemoveImage,
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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
