import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/constants/app_spacing.dart';
import 'package:real_state/core/utils/motion_utils.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/core/selection/property_selection_controller.dart';
import 'package:real_state/core/utils/property_placeholders.dart';
import 'package:real_state/features/properties/presentation/widgets/property_list_item.dart';

typedef PropertyListItemBuilder =
    Widget Function(
      BuildContext context,
      Property property,
      String areaName,
      bool isLoading,
      bool selectionMode,
      bool selected,
      VoidCallback onSelectToggle,
      VoidCallback onLongPressSelect,
      VoidCallback onOpen,
    );

class PropertyPaginatedListView extends StatelessWidget {
  const PropertyPaginatedListView({
    super.key,
    required this.refreshController,
    required this.items,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.hasMore = false,
    required this.onRefresh,
    required this.onLoadMore,
    this.onRetry,
    this.selectionMode = false,
    this.selectionController,
    this.selectedIds = const {},
    this.onToggleSelection,
    this.areaNames,
    this.startAreaName,
    this.canViewImages,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.emptyMessage,
    this.emptyAction,
    this.emptyFooter,
    this.itemBuilder,
  });

  final RefreshController refreshController;
  final List<Property> items;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final bool hasMore;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback? onRetry;

  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggleSelection;
  final PropertySelectionController? selectionController;

  final Map<String, LocationArea>? areaNames;
  final String? startAreaName;
  final bool? canViewImages;
  final EdgeInsetsGeometry padding;
  final String? emptyMessage;
  final VoidCallback? emptyAction;
  final Widget? emptyFooter;
  final PropertyListItemBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (isError && items.isEmpty) {
      content = AppErrorView(
        key: const ValueKey('properties_error'),
        message: errorMessage ?? 'generic_error'.tr(),
        onRetry: onRetry ?? onRefresh,
      );
    } else if (!isLoading && items.isEmpty) {
      if (emptyFooter != null) {
        content = Center(
          key: const ValueKey('properties_empty_with_footer'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyStateWidget(
                description: emptyMessage ?? 'no_properties_title'.tr(),
                action: emptyAction ?? onRefresh,
              ),
              const SizedBox(height: AppSpacing.lg),
              emptyFooter!,
            ],
          ),
        );
      } else {
        content = EmptyStateWidget(
          key: const ValueKey('properties_empty'),
          description: emptyMessage ?? 'no_properties_title'.tr(),
          action: emptyAction ?? onRefresh,
        );
      }
    } else {
      final displayItems = isLoading && items.isEmpty
          ? placeholderProperties()
          : items;

      content = SmartRefresher(
        key: const ValueKey('properties_list'),
        controller: refreshController,
        enablePullUp: hasMore,
        enablePullDown: true,
        onRefresh: onRefresh,
        onLoading: onLoadMore,
        child: AppSkeletonizer(
          enabled: isLoading && items.isEmpty,
          child: selectionController != null
              ? ValueListenableBuilder<Set<String>>(
                  valueListenable: selectionController!.selectedIds,
                  builder: (_, __, ___) =>
                      _buildListView(context, displayItems, isLoading),
                )
              : _buildListView(context, displayItems, isLoading),
        ),
      );
    }

    final shouldReduceMotion = reduceMotion(context);
    return AnimatedSwitcher(
      duration: shouldReduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        if (shouldReduceMotion) return child;
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: content,
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<Property> displayItems,
    bool isLoading,
  ) {
    return ListView.separated(
      padding: padding,
      itemCount: displayItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final property = displayItems[index];
        final resolvedAreaName = _resolveAreaName(context, property);

        if (property.id.isEmpty && isLoading) {
          return itemBuilder != null
              ? itemBuilder!(
                  context,
                  property,
                  resolvedAreaName,
                  isLoading,
                  false,
                  false,
                  () {},
                  () {},
                  () {},
                )
              : PropertyListItem(
                  property: property,
                  areaName: resolvedAreaName,
                );
        }

        final controllerIsActive =
            selectionController?.isSelectionActive ?? false;
        final effectiveSelectionMode = controllerIsActive || selectionMode;
        final isSelected =
            selectionController?.isSelected(property.id) ??
            selectedIds.contains(property.id);
        void handleSelection() {
          if (selectionController != null) {
            selectionController!.toggle(property.id);
          } else {
            onToggleSelection?.call(property.id);
          }
        }

        void openProperty() => context.push('/property/${property.id}');
        final child = itemBuilder != null
            ? itemBuilder!(
                context,
                property,
                resolvedAreaName,
                isLoading,
                effectiveSelectionMode,
                isSelected,
                handleSelection,
                handleSelection,
                effectiveSelectionMode ? handleSelection : openProperty,
              )
            : PropertyListItem(
                property: property,
                areaName: resolvedAreaName,
                canViewImages: canViewImages,
                selectionMode: effectiveSelectionMode,
                selected: isSelected,
                onSelectToggle: handleSelection,
                onLongPressSelect: handleSelection,
                onOpen: effectiveSelectionMode ? handleSelection : openProperty,
              );
        return RepaintBoundary(child: child);
      },
    );
  }

  String _resolveAreaName(BuildContext context, Property property) {
    if (startAreaName != null && startAreaName!.isNotEmpty) {
      return startAreaName!;
    }
    if (areaNames != null) {
      final area = areaNames![property.locationAreaId];
      if (area != null) {
        return area.localizedName(localeCode: context.locale.toString());
      }
    }
    return property.locationAreaId != null ? '...' : 'placeholder_dash'.tr();
  }
}
