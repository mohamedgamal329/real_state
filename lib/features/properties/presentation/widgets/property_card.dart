import 'package:flutter/material.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/core/components/pressable_scale.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card/property_card_header.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card/property_card_images.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card/property_card_meta.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
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

  final Property property;
  final String areaName;
  final VoidCallback onTap;
  final bool? canViewImages;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPressSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = 12.0;

    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.6)
        : colorScheme.outlineVariant.withValues(alpha: 0.4);
    return PressableScale(
      enabled: true,
      scale: 0.985,
      hoverScale: 0.99,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InkWell(
              onTap: selectionMode ? onSelectToggle : onTap,
              onLongPress: onLongPressSelect ?? onSelectToggle,
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: borderColor),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final imageWidth = (constraints.maxWidth * 0.35).clamp(
                      120.0,
                      170.0,
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: imageWidth,
                            child: PropertyCardImages(
                              property: property,
                              canViewImages: canViewImages,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PropertyCardHeader(
                                  property: property,
                                  areaName: areaName,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                PropertyCardMeta(property: property),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (selectionMode)
              Positioned.directional(
                textDirection: Directionality.of(context),
                top: 8,
                end: 8,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  child: AppSvgIcon(
                    selected ? AppSVG.check : AppSVG.radioUnchecked,
                    size: 18,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
