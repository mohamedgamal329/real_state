import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/core/components/pressable_scale.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/features/models/entities/location_area.dart';

class LocationAreaCard extends StatelessWidget {
  const LocationAreaCard({
    super.key,
    required this.area,
    required this.localeCode,
    this.footer,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  final LocationArea area;
  final String localeCode;
  final String? footer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = area.name.isNotEmpty
        ? area.name
        : 'placeholder_dash'.tr();
    return PressableScale(
      enabled: onTap != null || onEdit != null,
      scale: 0.985,
      hoverScale: 0.99,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? onEdit,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: LocationAreaImage(url: area.imageUrl),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          footer!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (onEdit != null || onDelete != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          onPressed: onEdit,
                          icon: const AppSvgIcon(AppSVG.edit),
                          tooltip: 'edit'.tr(),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const AppSvgIcon(AppSVG.delete),
                          color: theme.colorScheme.error,
                          tooltip: 'delete'.tr(),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LocationAreaImage extends StatelessWidget {
  const LocationAreaImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return AppNetworkImage(url: url, fit: BoxFit.cover);
    }
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: AppSvgIcon(
        AppSVG.imageOff,
        size: 40,
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}
