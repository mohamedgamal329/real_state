import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/components/app_network_image.dart';

import 'package:real_state/features/properties/models/property_editor_models.dart';

class PropertyImagesEditor extends StatelessWidget {
  final List<EditableImage> images;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemove;
  final ValueChanged<int> onSetCover;

  const PropertyImagesEditor({
    super.key,
    required this.images,
    required this.onPickImages,
    required this.onRemove,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'images_title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: onPickImages,
              icon: const AppSvgIcon(AppSVG.photo),
              label: Text('pick_images'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (images.isEmpty)
          Text(
            'no_images_selected'.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (images.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final img = images[index];
                return GestureDetector(
                  onTap: () => onSetCover(index),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 140,
                          height: 120,
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: _buildImageContent(context, img),
                        ),
                      ),
                      if (img.isCover)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'cover'.tr(),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => onRemove(index),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context, EditableImage img) {
    if (img.preview != null)
      return Image.memory(img.preview!, fit: BoxFit.cover);
    if (img.remoteUrl != null) {
      return AppNetworkImage(url: img.remoteUrl!, fit: BoxFit.cover);
    }
    return Icon(
      Icons.photo,
      size: 42,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
