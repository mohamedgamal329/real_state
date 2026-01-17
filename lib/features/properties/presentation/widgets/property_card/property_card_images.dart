import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/components/app_badge.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/core/utils/image_visibility.dart';
import 'package:easy_localization/easy_localization.dart';

class PropertyCardImages extends StatelessWidget {
  const PropertyCardImages({
    super.key,
    required this.property,
    required this.canViewImages,
  });

  final Property property;
  final bool? canViewImages;

  bool get _isNew =>
      DateTime.now().difference(property.createdAt).inHours < 24 &&
      property.status == PropertyStatus.active;

  bool get _isBrokerOwned => property.ownerScope == PropertyOwnerScope.broker;

  @override
  Widget build(BuildContext context) {
    final radius = 8.0;
    final allowImages = canViewPropertyImages(
      context: context,
      property: property,
      override: canViewImages,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: allowImages
          ? _imageWithBadges(context, radius)
          : _placeholder(context, radius),
    );
  }

  Widget _imageWithBadges(BuildContext context, double radius) {
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
    final lockColor = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0.72);
    return AspectRatio(
      aspectRatio: 2.1 / 2.3,
      child: Stack(
        children: [
          AppNetworkImage(
            url:
                property.coverImageUrl ??
                (property.imageUrls.isNotEmpty ? property.imageUrls[0] : ''),
            fit: BoxFit.cover,
            borderRadius: 0,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: overlayGradient),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Row(
              children: [
                AppBadge(
                  label: 'purpose.${property.purpose.name}'.tr().toUpperCase(),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.9),
                  textStyle: badgeTextStyle,
                ),
                if (_isNew) ...[
                  const SizedBox(width: 8),
                  AppBadge(
                    label: 'new'.tr(),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.9),
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.72),
                textStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, double radius) {
    return AspectRatio(
      aspectRatio: 2.1 / 2.3,
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: AppSvgIcon(AppSVG.imageOff, size: 36)),
      ),
    );
  }
}
