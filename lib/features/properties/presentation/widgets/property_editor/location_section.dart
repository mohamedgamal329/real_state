import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/features/location/presentation/widgets/location_picker_form_field.dart';
import 'package:real_state/features/location/presentation/widgets/sub_location_picker_form_field.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/sub_location.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyEditorLocationSection extends StatelessWidget {
  const PropertyEditorLocationSection({
    super.key,
    required this.locationUrlCtrl,
    required this.purpose,
    required this.locationId,
    required this.subLocationId,
    required this.locations,
    required this.subLocations,
    required this.onPurposeChanged,
    required this.onLocationChanged,
    required this.onSubLocationChanged,
    required this.onAddLocation,
    required this.locationUrlValidator,
    required this.purposeValidator,
    required this.locationValidator,
    required this.subLocationValidator,
  });

  final TextEditingController locationUrlCtrl;
  final PropertyPurpose purpose;
  final String? locationId;
  final String? subLocationId;
  final List<LocationArea> locations;
  final List<SubLocation> subLocations;
  final ValueChanged<PropertyPurpose> onPurposeChanged;
  final ValueChanged<String?> onLocationChanged;
  final ValueChanged<String?> onSubLocationChanged;
  final VoidCallback onAddLocation;
  final FormFieldValidator<String>? locationUrlValidator;
  final FormFieldValidator<PropertyPurpose>? purposeValidator;
  final FormFieldValidator<String?>? locationValidator;
  final FormFieldValidator<String?>? subLocationValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'location_url'.tr(),
          controller: locationUrlCtrl,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          validator: locationUrlValidator,
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
          validator: purposeValidator,
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
          validator: locationValidator,
        ),
        const SizedBox(height: 12),
        SubLocationPickerFormField(
          value: subLocationId,
          subLocations: subLocations,
          onChanged: onSubLocationChanged,
          validator: subLocationValidator,
          enabled: locationId != null && locationId!.isNotEmpty,
        ),
      ],
    );
  }
}
