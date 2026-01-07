import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/features/models/entities/location_area.dart';

class LocationPickerFormField extends StatelessWidget {
  final String? value;
  final List<LocationArea> locations;
  final ValueChanged<String?> onChanged;
  final VoidCallback onAddPressed;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool enabled;

  const LocationPickerFormField({
    super.key,
    required this.value,
    required this.locations,
    required this.onChanged,
    required this.onAddPressed,
    this.labelText,
    this.hintText,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return _buildEmptyState(context);
    }
    return _buildDropdownRow(context);
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
                  'locations_empty_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'locations_empty_desc'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: enabled ? onAddPressed : null,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text('locations_add_cta'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(BuildContext context) {
    final localeCode = context.locale.toString();
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: value,
            decoration: InputDecoration(
              labelText: labelText ?? 'location_area'.tr(),
              hintText: hintText,
              enabled: enabled,
            ),
            items: locations
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
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: enabled ? onAddPressed : null,
            icon: const Icon(Icons.add),
            tooltip: 'add_location'.tr(),
          ),
        ),
      ],
    );
  }
}
