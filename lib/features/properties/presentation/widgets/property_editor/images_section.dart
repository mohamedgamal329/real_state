import 'package:flutter/material.dart';
import 'package:real_state/features/properties/models/property_editor_models.dart';
import 'package:real_state/features/properties/presentation/widgets/property_images_editor.dart';

class PropertyEditorImagesSection extends StatelessWidget {
  const PropertyEditorImagesSection({
    super.key,
    required this.images,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSetCover,
  });

  final List<EditableImage> images;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final ValueChanged<int> onSetCover;

  @override
  Widget build(BuildContext context) {
    return PropertyImagesEditor(
      images: images,
      onPickImages: onPickImages,
      onRemove: onRemoveImage,
      onSetCover: onSetCover,
    );
  }
}
