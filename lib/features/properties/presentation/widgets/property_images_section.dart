import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_network_image.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/features/models/entities/property.dart';

class PropertyImagesSection extends StatelessWidget {
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
      // Do not instantiate any image widgets when visibility is denied to avoid
      // accidental leaks via caches or shared widgets.
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock, size: 32),
              const SizedBox(height: 8),
              Text(
                'images_hidden'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (onRequestAccess != null) ...[
                const SizedBox(height: 12),
                PrimaryButton(
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
