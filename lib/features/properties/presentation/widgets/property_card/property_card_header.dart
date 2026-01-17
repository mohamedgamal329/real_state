import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyCardHeader extends StatelessWidget {
  const PropertyCardHeader({
    super.key,
    required this.property,
    required this.areaName,
  });

  final Property property;
  final String areaName;

  String get _title {
    final title = property.title;
    if (title == null || title.trim().isEmpty) {
      return 'untitled'.tr();
    }
    return title;
  }

  String _areaLabel(BuildContext context) {
    if (areaName.isNotEmpty) return areaName;
    return 'area_unavailable'.tr();
  }

  String get _timeLabel => _timeAgo(property.createdAt);

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return '$m ${'minutes'.tr()}';
    }
    if (diff.inHours < 48) {
      final h = diff.inHours;
      return '$h ${'hours'.tr()}';
    }
    final d = diff.inDays;
    return '$d ${'days'.tr()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final price = PriceFormatter.format(property.price ?? 0, currency: AED);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                price,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AED',
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 1,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _timeLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppSvgIcon(AppSVG.locationOn, size: 16, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                _areaLabel(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (property.creatorName != null &&
            property.creatorName!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  property.creatorName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
