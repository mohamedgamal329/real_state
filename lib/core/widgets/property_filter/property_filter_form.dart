import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';

import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_colors.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';

class PropertyFilterForm extends StatelessWidget {
  const PropertyFilterForm({
    super.key,
    required this.formKey,
    required this.locationField,
    required this.roomsField,
    required this.minPriceController,
    required this.maxPriceController,
    required this.hasPool,
    required this.onHasPoolChanged,
    required this.onApply,
    required this.onClear,
    required this.isApplyEnabled,
    required this.showEmptyLocations,
    required this.onAddLocation,
    this.validationErrorKey,
    this.minPriceFieldKey,
    this.maxPriceFieldKey,
    this.applyButtonKey,
    this.clearButtonKey,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xl,
      AppSpacing.xxl,
    ),
  });

  final GlobalKey<FormState> formKey;
  final Widget locationField;
  final Widget roomsField;
  final TextEditingController minPriceController;
  final TextEditingController maxPriceController;
  final bool hasPool;
  final ValueChanged<bool> onHasPoolChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final bool isApplyEnabled;
  final bool showEmptyLocations;
  final Future<void> Function() onAddLocation;
  final String? validationErrorKey;
  final Key? minPriceFieldKey;
  final Key? maxPriceFieldKey;
  final Key? applyButtonKey;
  final Key? clearButtonKey;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorKey = validationErrorKey;
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'filter_properties'.tr(),
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(onPressed: onClear, child: Text('clear'.tr())),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SectionHeader(label: 'filter_location_label'.tr()),
            const SizedBox(height: AppSpacing.sm),
            if (showEmptyLocations)
              _EmptyLocations(onAdd: onAddLocation)
            else
              locationField,
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(label: 'price_range'.tr()),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'min_price'.tr(),
                    key: minPriceFieldKey,
                    controller: minPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        AED,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AED',
                        ),
                      ),
                    ),
                    validator: (_) => errorKey?.tr(),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'max_price'.tr(),
                    key: maxPriceFieldKey,
                    controller: maxPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Text(
                        AED,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AED',
                        ),
                      ),
                    ),
                    validator: (_) => errorKey?.tr(),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                ),
              ],
            ),
            if (errorKey != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  errorKey.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(label: 'rooms_label'.tr()),
            const SizedBox(height: AppSpacing.sm),
            roomsField,
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(label: 'has_pool'.tr()),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('has_pool'.tr(), style: theme.textTheme.bodyMedium),
                  Switch(value: hasPool, onChanged: onHasPoolChanged),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            // PrimaryButton(
            //   key: applyButtonKey,
            //   label: 'apply_filters'.tr(),
            //   onPressed: () {
            //     onApply();
            //   },
            //   //onPressed: isApplyEnabled ? onApply : null,
            // ),
            ElevatedButton(
              key: applyButtonKey,
              onPressed: isApplyEnabled ? onApply : null,
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.primary),
              ),
              child: Text('apply_filters'.tr()),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: clearButtonKey,
              onPressed: onClear,
              child: Text('clear_filters'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyLocations extends StatelessWidget {
  final Future<void> Function() onAdd;

  const _EmptyLocations({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'locations_empty_title'.tr(),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'filter_location_empty_hint'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              await onAdd();
            },
            icon: const AppSvgIcon(AppSVG.add),
            label: Text('locations_add_cta'.tr()),
          ),
        ],
      ),
    );
  }
}
