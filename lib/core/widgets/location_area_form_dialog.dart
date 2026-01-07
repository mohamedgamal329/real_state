import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/models/entities/location_area.dart';

class LocationAreaFormResult {
  final String nameAr;
  final String nameEn;
  final XFile? imageFile;

  const LocationAreaFormResult({
    required this.nameAr,
    required this.nameEn,
    this.imageFile,
  });
}

class LocationAreaFormDialog {
  const LocationAreaFormDialog._();

  static Future<LocationAreaFormResult?> show(
    BuildContext context, {
    LocationArea? initial,
  }) async {
    final nameArCtrl = TextEditingController(text: initial?.nameAr ?? '');
    final nameEnCtrl = TextEditingController(text: initial?.nameEn ?? '');
    final formKey = GlobalKey<FormState>();
    XFile? imageFile;
    bool showImageError = false;

    final result = await showDialog<LocationAreaFormResult>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return AlertDialog(
              title: Text(
                initial == null ? 'add_location'.tr() : 'edit_location'.tr(),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocationAreaImagePicker(
                        imageFile: imageFile,
                        existingUrl: initial?.imageUrl ?? '',
                        onPick: (file) {
                          setState(() {
                            imageFile = file;
                            showImageError = false;
                          });
                        },
                      ),
                      if (showImageError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'location_image_required'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'name_ar_label'.tr(),
                        controller: nameArCtrl,
                        validator: (v) => Validators.isNotEmpty(v)
                            ? null
                            : 'name_ar_required'.tr(),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'name_en_label'.tr(),
                        controller: nameEnCtrl,
                        validator: (v) => Validators.isNotEmpty(v)
                            ? null
                            : 'name_en_required'.tr(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                PrimaryButton(
                  label: initial == null ? 'add'.tr() : 'save'.tr(),
                  expand: false,
                  onPressed: () {
                    final valid = formKey.currentState?.validate() ?? false;
                    final hasImageNow =
                        imageFile != null ||
                        (initial?.imageUrl.isNotEmpty ?? false);
                    setState(() => showImageError = !hasImageNow);
                    if (!valid || !hasImageNow) return;
                    Navigator.of(context).pop(
                      LocationAreaFormResult(
                        nameAr: nameArCtrl.text.trim(),
                        nameEn: nameEnCtrl.text.trim(),
                        imageFile: imageFile,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
    nameArCtrl.dispose();
    nameEnCtrl.dispose();
    return result;
  }
}

class _LocationAreaImagePicker extends StatelessWidget {
  const _LocationAreaImagePicker({
    required this.imageFile,
    required this.existingUrl,
    required this.onPick,
  });

  final XFile? imageFile;
  final String existingUrl;
  final ValueChanged<XFile> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget preview;
    if (imageFile != null) {
      preview = Image.file(File(imageFile!.path), fit: BoxFit.cover);
    } else if (existingUrl.isNotEmpty) {
      preview = AppNetworkImage(url: existingUrl, fit: BoxFit.cover);
    } else {
      preview = Center(
        child: Icon(
          Icons.photo_outlined,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (picked != null) {
          onPick(picked);
        }
      },
      child: Ink(
        height: 170,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: preview,
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_camera_back_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      imageFile != null || existingUrl.isNotEmpty
                          ? 'replace_image'.tr()
                          : 'pick_image'.tr(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
