import 'package:flutter/material.dart';
import 'package:real_state/features/properties/presentation/widgets/property_image_viewer.dart';

class PropertyImageViewerArgs {
  final List<String> images;
  final int initialIndex;

  const PropertyImageViewerArgs({required this.images, this.initialIndex = 0});
}

class PropertyImageViewerPage extends StatelessWidget {
  final PropertyImageViewerArgs args;
  const PropertyImageViewerPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return PropertyImageViewer(
      images: args.images,
      initialIndex: args.initialIndex,
    );
  }
}
