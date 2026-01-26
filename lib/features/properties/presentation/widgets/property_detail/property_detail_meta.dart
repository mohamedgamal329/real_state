import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyDetailMetaSection extends StatelessWidget {
  const PropertyDetailMetaSection({
    super.key,
    required this.property,
    required this.surfaceColor,
  });

  final Property property;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = property;
    final chips = <Widget>[];
    if (p.rooms != null) {
      chips.add(
        _InfoChip(
          icon: const AppSvgIcon(AppSVG.bed, size: 18),
          label: 'rooms_with_value'.tr(args: [p.rooms.toString()]),
        ),
      );
    }
    if (p.kitchens != null) {
      chips.add(
        _InfoChip(
          icon: const AppSvgIcon(AppSVG.kitchen, size: 18),
          label: 'kitchens_with_value'.tr(args: [p.kitchens.toString()]),
        ),
      );
    }
    if (p.floors != null) {
      chips.add(
        _InfoChip(
          icon: const AppSvgIcon(AppSVG.floors, size: 18),
          label: 'floors_with_value'.tr(args: [p.floors.toString()]),
        ),
      );
    }
    chips.add(
      _InfoChip(
        icon: const AppSvgIcon(AppSVG.flag, size: 18),
        label: 'purpose_with_value'.tr(
          args: ['purpose.${p.purpose.name}'.tr()],
        ),
      ),
    );
    chips.add(
      _InfoChip(
        icon: const AppSvgIcon(AppSVG.success, size: 18),
        label: 'status_with_value'.tr(
          args: ['property_status_${p.status.name}'.tr()],
        ),
      ),
    );
    if (p.hasPool) {
      chips.add(
        _InfoChip(
          icon: const AppSvgIcon(AppSVG.pools, size: 18),
          label: 'has_pool_with_value'.tr(args: ['yes'.tr()]),
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('details'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Chip(
      avatar: IconTheme(
        data: IconThemeData(color: colorScheme.primary),
        child: icon,
      ),
      label: Text(label, style: theme.textTheme.bodyMedium),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }
}
