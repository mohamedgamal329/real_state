import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card.dart';

class PropertyListItem extends StatelessWidget {
  final Property property;
  final String areaName;
  final bool? canViewImages;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPressSelect;
  final VoidCallback? onOpen;

  const PropertyListItem({
    super.key,
    required this.property,
    required this.areaName,
    this.canViewImages,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    this.onLongPressSelect,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      tween: Tween(begin: 0.95, end: 1.0),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: PropertyCard(
        property: property,
        areaName: areaName,
        onTap: selectionMode
            ? (onSelectToggle ?? () {})
            : (onOpen ?? () => context.push('/property/${property.id}')),
        canViewImages: canViewImages,
        selectionMode: selectionMode,
        selected: selected,
        onSelectToggle: onSelectToggle,
        onLongPressSelect: onLongPressSelect ?? onSelectToggle,
      ),
    );
  }
}
