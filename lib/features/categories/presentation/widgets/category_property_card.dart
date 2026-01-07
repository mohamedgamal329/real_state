import 'package:flutter/material.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card.dart';

class CategoryPropertyCard extends StatelessWidget {
  final Property property;
  final String areaName;
  final VoidCallback onTap;
  final bool? canViewImages;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPressSelect;

  const CategoryPropertyCard({
    super.key,
    required this.property,
    required this.areaName,
    required this.onTap,
    this.canViewImages,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    this.onLongPressSelect,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyCard(
      property: property,
      areaName: areaName,
      onTap: onTap,
      canViewImages: canViewImages,
       selectionMode: selectionMode,
       selected: selected,
       onSelectToggle: onSelectToggle,
       onLongPressSelect: onLongPressSelect,
    );
  }
}
