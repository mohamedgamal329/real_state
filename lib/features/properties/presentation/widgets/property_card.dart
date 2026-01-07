import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_badge.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/core/constants/aed_text.dart';
import 'package:real_state/core/utils/price_formatter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/utils/image_visibility.dart';

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

  bool get _isNew =>
      DateTime.now().difference(property.createdAt).inHours < 24 &&
      property.status == PropertyStatus.active;
  bool get _isBrokerOwned => property.ownerScope == PropertyOwnerScope.broker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final radius = 12.0;

    final borderColor = selected
        ? colorScheme.primary.withValues(alpha: 0.6)
        : colorScheme.outlineVariant.withValues(alpha: 0.4);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
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
                  final imageWidth = (constraints.maxWidth * 0.35).clamp(120.0, 170.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: imageWidth, child: _buildImage(context, radius - 4)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPriceRow(textTheme, colorScheme),
                              const SizedBox(height: 4),
                              _buildTitleLocation(textTheme, colorScheme),
                              const SizedBox(height: 6),
                              _buildMetaRow(textTheme, colorScheme),
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
                child: Icon(
                  selected ? Icons.check : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context, double radius) {
    final allowImages = canViewPropertyImages(
      context: context,
      property: property,
      override: canViewImages,
    );
    final overlayGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.black.withValues(alpha: 0.04),
        Theme.of(context).colorScheme.scrim.withValues(alpha: 0.36),
      ],
    );
    final badgeTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onPrimary,
      fontWeight: FontWeight.w700,
    );
    final lockColor = Theme.of(context).colorScheme.surface.withValues(alpha: 0.72);

    if (!allowImages) {
      return _imagePlaceholder(context, radius);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        children: [
          AspectRatio(aspectRatio: 2.1 / 2.3, child: _coverImage()),
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(gradient: overlayGradient)),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Row(
              children: [
                AppBadge(
                  label: 'purpose.${property.purpose.name}'.tr().toUpperCase(),
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                  textStyle: badgeTextStyle,
                ),
                if (_isNew) ...[
                  const SizedBox(width: 8),
                  AppBadge(
                    label: 'new'.tr(),
                    backgroundColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.9),
                    textStyle: badgeTextStyle,
                  ),
                ],
              ],
            ),
          ),
          if (property.isImagesHidden)
            Positioned(
              top: 10,
              right: 10,
              child: AppBadge(
                label: '🔒',
                backgroundColor: lockColor,
                textStyle: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (_isBrokerOwned)
            Positioned(
              top: 10,
              left: 10,
              child: AppBadge(
                label: 'broker_label'.tr(),
                backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                textStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coverImage() {
    final cover =
        property.coverImageUrl ?? (property.imageUrls.isNotEmpty ? property.imageUrls[0] : '');
    if (cover.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.photo, size: 48, color: Colors.black26),
      );
    }
    return AppNetworkImage(url: cover, fit: BoxFit.cover, borderRadius: 0);
  }

  Widget _imagePlaceholder(BuildContext context, double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 2.1 / 2.3,
        child: Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 36)),
        ),
      ),
    );
  }

  Widget _buildPriceRow(TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Text(
            PriceFormatter.format(property.price ?? 0, currency: AED),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontFamily: 'AED',
              fontSize: 18,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 1, color: colorScheme.onPrimaryContainer),
              const SizedBox(width: 4),
              Text(
                _timeAgo(property.createdAt),
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleLocation(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.title ?? 'untitled'.tr(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.place_outlined, size: 16, color: colorScheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                areaName.isNotEmpty ? areaName : 'area_unavailable'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        if (property.creatorName != null && property.creatorName!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: colorScheme.secondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.creatorName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
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

  Widget _buildMetaRow(TextTheme textTheme, ColorScheme colorScheme) {
    final items = <Widget>[];
    if (property.rooms != null) {
      items.add(_MetaItem(icon: Icons.king_bed_outlined, label: '${property.rooms}'));
    }
    if (property.kitchens != null) {
      items.add(_MetaItem(icon: Icons.restaurant_outlined, label: '${property.kitchens}'));
    }
    if (property.floors != null) {
      items.add(_MetaItem(icon: Icons.layers_outlined, label: '${property.floors}'));
    }
    if (property.hasPool) {
      items.add(
        _MetaItem(
          icon: Icons.pool,
          label: 'has_pool_with_value'.tr(args: ['yes'.tr()]),
        ),
      );
    }
    final phoneLocked =
        property.ownerPhoneEncryptedOrHiddenStored != null &&
        property.ownerPhoneEncryptedOrHiddenStored!.isNotEmpty;
    if (phoneLocked) {
      items.add(_MetaItem(icon: Icons.lock_outline, label: 'phone'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(spacing: 12, runSpacing: 8, children: items);
  }

  String _timeAgo(DateTime date) {
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
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
