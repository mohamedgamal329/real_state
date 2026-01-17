import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyImagesSection extends StatelessWidget {
  static const ValueKey<String> hiddenImagesKey = ValueKey(
    'property_images_hidden_card',
  );
  static const ValueKey<String> hiddenImagesLabelKey = ValueKey(
    'property_images_hidden',
  );
  static const ValueKey<String> requestAccessButtonKey = ValueKey(
    'property_images_request_button',
  );

  final Property property;
  final bool imagesVisible;
  final ScrollController scrollController;
  final int imagesToShow;
  final VoidCallback? onRequestAccess;
  final bool showSkeleton;
  final ValueChanged<int>? onImageTap;

  const PropertyImagesSection({
    super.key,
    required this.property,
    required this.imagesVisible,
    required this.scrollController,
    required this.imagesToShow,
    this.onRequestAccess,
    this.onImageTap,
    this.showSkeleton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (showSkeleton) {
      return SizedBox(
        height: 160,
        child: ListView.separated(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 200,
            height: 160,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (!imagesVisible) {
      return Card(
        key: hiddenImagesKey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const AppSvgIcon(AppSVG.lock, size: 32),
              const SizedBox(height: 8),
              Text(
                'images_hidden'.tr(),
                key: hiddenImagesLabelKey,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (onRequestAccess != null) ...[
                const SizedBox(height: 12),
                PrimaryButton(
                  key: requestAccessButtonKey,
                  label: 'request_images_access'.tr(),
                  onPressed: onRequestAccess,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: (property.imageUrls.length < imagesToShow)
            ? property.imageUrls.length
            : imagesToShow,
        itemBuilder: (c, i) => Padding(
          padding: EdgeInsets.only(right: i == imagesToShow - 1 ? 0 : 12.0),
          child: GestureDetector(
            onTap: onImageTap != null ? () => onImageTap!(i) : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AppNetworkImage(
                url: property.imageUrls[i],
                width: 200,
                height: 160,
                borderRadius: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
