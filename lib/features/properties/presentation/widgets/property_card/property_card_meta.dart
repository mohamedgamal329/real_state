import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyCardMeta extends StatelessWidget {
  const PropertyCardMeta({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    if (property.rooms != null) {
      items.add(
        _MetaItem(
          icon: const AppSvgIcon(AppSVG.bed, size: 16),
          label: '${property.rooms}',
        ),
      );
    }
    if (property.kitchens != null) {
      items.add(
        _MetaItem(
          icon: const AppSvgIcon(AppSVG.kitchen, size: 16),
          label: '${property.kitchens}',
        ),
      );
    }
    if (property.floors != null) {
      items.add(
        _MetaItem(
          icon: const AppSvgIcon(AppSVG.floors, size: 16),
          label: '${property.floors}',
        ),
      );
    }
    if (property.hasPool) {
      items.add(
        _MetaItem(
          icon: const AppSvgIcon(AppSVG.pools, size: 16),
          label: 'has_pool_with_value'.tr(args: ['yes'.tr()]),
        ),
      );
    }
    final phoneLocked =
        property.ownerPhoneEncryptedOrHiddenStored?.isNotEmpty ?? false;
    if (phoneLocked) {
      items.add(
        _MetaItem(
          icon: const AppSvgIcon(AppSVG.lock, size: 16),
          label: 'phone',
        ),
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 12, runSpacing: 8, children: items);
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: colorScheme.primary),
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
