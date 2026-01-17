import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/constants/app_spacing.dart';

class PropertyListScaffold extends StatelessWidget {
  final RefreshController controller;
  final bool isInitialLoading;
  final bool hasMore;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const PropertyListScaffold({
    super.key,
    required this.controller,
    required this.isInitialLoading,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.itemCount,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller,
      enablePullUp: hasMore,
      onRefresh: onRefresh,
      onLoading: onLoadMore,
      child: AppSkeletonizer(
        enabled: isInitialLoading,
        child: ListView.separated(
          padding: padding,
          itemBuilder: itemBuilder,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemCount: itemCount,
        ),
      ),
    );
  }
}
