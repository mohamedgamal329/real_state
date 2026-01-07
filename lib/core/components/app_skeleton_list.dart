import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';

class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsetsGeometry padding;
  final double separatorHeight;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AppSkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(12),
    this.separatorHeight = 8,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: true,
      child: ListView.separated(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (context, index) => SizedBox(height: separatorHeight),
      ),
    );
  }
}
