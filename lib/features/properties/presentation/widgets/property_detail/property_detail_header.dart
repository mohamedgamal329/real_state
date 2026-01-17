import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyDetailHeader extends StatelessWidget {
  const PropertyDetailHeader({
    super.key,
    required this.title,
    required this.price,
    required this.purpose,
    required this.createdAt,
    required this.addedBy,
  });

  final String title;
  final double? price;
  final PropertyPurpose purpose;
  final DateTime createdAt;
  final String addedBy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'purpose.${purpose.name}'.tr().toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (price != null)
          Text(
            PriceFormatter.format(
              price!,
              currency: AED,
              locale: locale.toString(),
            ),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'AED',
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '${'added_by'.tr()}: $addedBy',
          style: textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
