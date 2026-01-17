import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcon extends StatelessWidget {
  final String asset;
  final double? size;
  final Color? color;
  final String? semanticsLabel;
  final BoxFit fit;

  const AppSvgIcon(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticsLabel,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize = size ?? iconTheme.size;
    final resolvedColor = color ?? iconTheme.color;
    return SvgPicture.asset(
      asset,
      width: resolvedSize,
      height: resolvedSize,
      fit: fit,
      semanticsLabel: semanticsLabel,
      colorFilter: resolvedColor != null
          ? ColorFilter.mode(resolvedColor, BlendMode.srcIn)
          : null,
    );
  }
}
