import 'package:flutter/material.dart';
import 'package:real_state/core/constants/app_images.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 150,
    this.width = 150,
    this.radius = 16,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadiusGeometry.circular(radius),
      child: Image.asset(
        AppImages.logo,
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
