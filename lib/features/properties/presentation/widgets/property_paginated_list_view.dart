import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/selection/property_selection_controller.dart';
import 'package:real_state/features/properties/presentation/utils/property_placeholders.dart';
import 'package:real_state/features/properties/presentation/widgets/property_list_item.dart';

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
    this.padding = const EdgeInsets.all(12),
    this.emptyMessage,
    this.emptyAction,
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

  @override
  Widget build(BuildContext context) {
    if (isError && items.isEmpty) {
      return AppErrorView(
        message: errorMessage ?? 'generic_error'.tr(),
        onRetry: onRetry ?? onRefresh,
      );
    }

    if (!isLoading && items.isEmpty) {
      return EmptyStateWidget(
        description: emptyMessage ?? 'no_properties_title'.tr(),
        action: emptyAction ?? onRefresh,
      );
    }

    final displayItems = isLoading && items.isEmpty ? placeholderProperties() : items;

    return SmartRefresher(
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
                builder: (_, __, ___) => _buildListView(context, displayItems, isLoading),
              )
            : _buildListView(context, displayItems, isLoading),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<Property> displayItems, bool isLoading) {
    return ListView.separated(
      padding: padding,
      itemCount: displayItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final property = displayItems[index];
        final resolvedAreaName = _resolveAreaName(context, property);

        if (property.id.isEmpty && isLoading) {
          return PropertyListItem(property: property, areaName: resolvedAreaName);
        }

        final controllerIsActive = selectionController?.isSelectionActive ?? false;
        final effectiveSelectionMode = controllerIsActive || selectionMode;
        final isSelected =
            selectionController?.isSelected(property.id) ?? selectedIds.contains(property.id);
        void handleSelection() {
          if (selectionController != null) {
            selectionController!.toggle(property.id);
          } else {
            onToggleSelection?.call(property.id);
          }
        }

        return PropertyListItem(
          property: property,
          areaName: resolvedAreaName,
          canViewImages: canViewImages,
          selectionMode: effectiveSelectionMode,
          selected: isSelected,
          onSelectToggle: handleSelection,
          onLongPressSelect: handleSelection,
          onOpen: effectiveSelectionMode
              ? handleSelection
              : () => context.push('/property/${property.id}'),
        );
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
