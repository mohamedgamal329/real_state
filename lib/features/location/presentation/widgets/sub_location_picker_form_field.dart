import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/models/entities/sub_location.dart';

class SubLocationPickerFormField extends StatelessWidget {
  final String? value;
  final List<SubLocation> subLocations;
  final ValueChanged<String?> onChanged;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const SubLocationPickerFormField({
    super.key,
    required this.value,
    required this.subLocations,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (subLocations.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildDropdown(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'sub_locations_empty_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'sub_locations_empty_desc'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const AppSvgIcon(AppSVG.locationOn),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final localeCode = context.locale.toString();
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: labelText ?? 'sub_location'.tr(),
        hintText: hintText,
        enabled: enabled,
      ),
      items: subLocations
          .map(
            (loc) => DropdownMenuItem(
              value: loc.id,
              child: Text(
                loc.localizedName(localeCode: localeCode).isNotEmpty
                    ? loc.localizedName(localeCode: localeCode)
                    : 'placeholder_dash'.tr(),
              ),
            ),
          )
          .toList(),
      validator: validator,
      onChanged: enabled ? onChanged : null,
    );
  }
}
