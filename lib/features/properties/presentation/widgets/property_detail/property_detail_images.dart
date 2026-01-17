import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/widgets/property_images_section.dart';

class PropertyDetailImagesSection extends StatelessWidget {
  const PropertyDetailImagesSection({
    super.key,
    required this.property,
    required this.imagesVisible,
    required this.scrollController,
    required this.imagesToShow,
    required this.showSkeleton,
    required this.onRequestAccess,
    required this.onImageTap,
  });

  final Property property;
  final bool imagesVisible;
  final ScrollController scrollController;
  final int imagesToShow;
  final bool showSkeleton;
  final VoidCallback? onRequestAccess;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('images'.tr(), style: textTheme.titleMedium),
        const SizedBox(height: 8),
        PropertyImagesSection(
          property: property,
          imagesVisible: imagesVisible,
          scrollController: scrollController,
          imagesToShow: imagesToShow,
          showSkeleton: showSkeleton,
          onRequestAccess: onRequestAccess,
          onImageTap: onImageTap,
        ),
      ],
    );
  }
}
