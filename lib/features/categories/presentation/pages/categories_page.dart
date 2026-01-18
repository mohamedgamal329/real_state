import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/selection/property_selection_policy.dart';
import 'package:real_state/core/selection/selection_app_bar.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';

import 'package:real_state/core/widgets/property_filter/filter_bottom_sheet.dart';
import 'package:real_state/core/widgets/property_paginated_list_view.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/notifications/presentation/widgets/notifications_icon_button.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';
import 'package:real_state/features/categories/presentation/widgets/category_property_card.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';
import 'package:real_state/features/models/entities/property.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with AutomaticKeepAliveClientMixin {
  late RefreshController _refreshController;
  final Set<String> _selected = {};
  List<Property> _currentItems = const [];

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  bool get _selectionMode => _selected.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  Future<void> _shareSelected() async {
    final props = _currentItems.where((p) => _selected.contains(p.id)).toList();
    if (props.isEmpty) return;
    await shareMultiplePropertyPdfs(context: context, properties: props);
    _clearSelection();
  }

  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _selectionMode
          ? SelectionAppBar(
              selectedCount: _selected.length,
              policy: const PropertySelectionPolicy(
                actions: [PropertyBulkAction.share],
              ),
              actionCallbacks: {PropertyBulkAction.share: _shareSelected},
              onClearSelection: _clearSelection,
            )
          : CustomAppBar(
              title: 'categories'.tr(),
              leading: _showResults
                  ? BackButton(
                      onPressed: () {
                        setState(() => _showResults = false);
                      },
                    )
                  : null,
              actions: [
                const NotificationsIconButton(),
                if (_showResults)
                  BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, state) {
                      return IconButton(
                        onPressed: () {
                          // Allow re-opening filter as modal (or just switch back to filter view?)
                          // Requirement says "Back returns to filter".
                          // Let's just switch back to filter view.
                          setState(() => _showResults = false);
                        },
                        icon: const AppSvgIcon(AppSVG.filter),
                      );
                    },
                  ),
              ],
            ),
      body: BaseGradientPage(
        child: BlocConsumer<CategoriesCubit, CategoriesState>(
          listener: (context, state) {
            if (state is CategoriesLoadSuccess ||
                state is CategoriesPartialFailure) {
              final data = state as CategoriesListState;
              _refreshController.refreshCompleted();
              if (data.hasMore) {
                _refreshController.loadComplete();
              } else {
                _refreshController.loadNoData();
              }
            } else if (state is CategoriesFailure) {
              _refreshController.refreshFailed();
              _refreshController.loadFailed();
            }
          },
          builder: (context, state) {
            final core = state is CategoriesCoreState
                ? state
                : const CategoriesInitial();
            final dataState = state is CategoriesListState ? state : null;
            final isInitialLoading =
                state is CategoriesInitial || state is CategoriesLoadInProgress;
            final isFilterEmpty = core.filter.isEmpty;

            final items = dataState?.items ?? const [];
            _currentItems = items.where((p) => p.id.isNotEmpty).toList();

            final isError =
                state is CategoriesFailure ||
                (state is CategoriesPartialFailure && items.isEmpty);
            final errorMessage = state is CategoriesFailure
                ? state.message
                : (state is CategoriesPartialFailure ? state.message : null);

            if (!_showResults) {
              return FilterBottomSheet(
                currentFilter: core.filter,
                locationAreas: null, // Uses Cubit
                onAddLocation: () async {}, // TODO: Implement if needed
                onApply: (filter) {
                  context.read<CategoriesCubit>().applyFilter(filter);
                  setState(() => _showResults = true);
                },
                onClear: () {
                  context.read<CategoriesCubit>().clearFilters();
                  // Stay in filter view on clear? Or go to results?
                  // Usually clear updates the filter state.
                  // Let's keep it in filter view to let user see it's cleared.
                },
                closeOnApply: false,
                closeOnClear: false,
              );
            }

            return PropertyPaginatedListView(
              refreshController: _refreshController,
              items: items,
              isLoading: isInitialLoading,
              isError: isError,
              errorMessage: errorMessage,
              hasMore: dataState?.hasMore ?? false,
              areaNames: core.areaNames,
              onRefresh: () => context.read<CategoriesCubit>().refresh(),
              onLoadMore: () => context.read<CategoriesCubit>().loadMore(),
              onRetry: () => context.read<CategoriesCubit>().loadFirstPage(),
              emptyMessage: isFilterEmpty
                  ? 'filter_properties'.tr()
                  : 'no_properties_title'.tr(),
              emptyAction: isFilterEmpty
                  ? () => setState(() => _showResults = false)
                  : () => context.read<CategoriesCubit>().loadFirstPage(),
              emptyFooter: !isInitialLoading && items.isEmpty && !isFilterEmpty
                  ? TextButton(
                      onPressed: () =>
                          context.read<CategoriesCubit>().clearFilters(),
                      child: Text('clear_filters'.tr()),
                    )
                  : null,
              selectionMode: _selectionMode,
              selectedIds: _selected,
              onToggleSelection: _toggleSelection,
              itemBuilder:
                  (
                    context,
                    property,
                    areaName,
                    isLoading,
                    selectionMode,
                    selected,
                    onSelectToggle,
                    onLongPressSelect,
                    onOpen,
                  ) {
                    return CategoryPropertyCard(
                      property: property,
                      areaName: areaName,
                      selectionMode: selectionMode,
                      selected: selected,
                      onSelectToggle: onSelectToggle,
                      onLongPressSelect: onLongPressSelect,
                      onTap: onOpen,
                    );
                  },
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
