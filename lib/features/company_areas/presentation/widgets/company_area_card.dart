import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/core/components/pressable_scale.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/features/company_areas/domain/entities/company_area_summary.dart';

class CompanyAreaCard extends StatelessWidget {
  final AreaSummary area;
  final VoidCallback? onTap;

  const CompanyAreaCard({super.key, required this.area, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = area.name.isNotEmpty ? area.name : 'area_unavailable'.tr();
    final countLabel = 'properties_count_format'.tr(
      args: [area.count.toString()],
    );
    return PressableScale(
      enabled: onTap != null,
      scale: 0.985,
      hoverScale: 0.99,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                if (area.imageUrl.isNotEmpty)
                  AppNetworkImage(
                    url: area.imageUrl,
                    width: 86,
                    height: 86,
                    borderRadius: 14,
                    fit: BoxFit.cover,
                    errorBuilder: (_) => _AreaImagePlaceholder(name: name),
                    placeholderBuilder: (_) =>
                        _AreaImagePlaceholder(name: name),
                  )
                else
                  _AreaImagePlaceholder(name: name),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        countLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const AppSvgIcon(AppSVG.chevronRight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaImagePlaceholder extends StatelessWidget {
  final String name;
  const _AreaImagePlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = name.isNotEmpty
        ? name.characters.take(2).toString()
        : '--';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 86,
        height: 86,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        ),
        child: Center(
          child: Text(
            initials,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
