import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/core/selection/property_selection_policy.dart';
import 'package:real_state/core/selection/selection_app_bar.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/core/widgets/property_filter/show_property_filter_bottom_sheet.dart';
import 'package:real_state/features/company_areas/presentation/controller/company_area_properties_controller.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/company_areas/presentation/pages/company_area_properties/company_properties_bloc.dart';
import 'package:real_state/features/company_areas/presentation/pages/company_area_properties/company_properties_event.dart';
import 'package:real_state/features/company_areas/presentation/pages/company_area_properties/company_properties_state.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';
import 'package:real_state/core/widgets/property_paginated_list_view.dart';

class CompanyAreaPropertiesPage extends StatefulWidget {
  final String areaId;
  final String areaName;

  const CompanyAreaPropertiesPage({
    super.key,
    required this.areaId,
    required this.areaName,
  });

  @override
  State<CompanyAreaPropertiesPage> createState() =>
      _CompanyAreaPropertiesPageState();
}

class _CompanyAreaPropertiesPageState extends State<CompanyAreaPropertiesPage> {
  late final CompanyPropertiesBloc _bloc;
  late final RefreshController _refreshController;
  final Set<String> _selected = {};
  List<Property> _currentItems = const [];
  late PropertyFilter _filter;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _filter = PropertyFilter(locationAreaId: widget.areaId);
    _bloc = context.read<CompanyAreaPropertiesController>().createBloc(
      filter: _filter,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _bloc.close();
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

  Future<void> _shareSelected(List<Property> properties) async {
    final selectedProps = properties
        .where((p) => _selected.contains(p.id))
        .toList();
    if (selectedProps.isEmpty) return;
    await shareMultiplePropertyPdfs(
      context: context,
      properties: selectedProps,
    );
    _clearSelection();
  }

  LocationArea _fallbackArea(String areaLabel) {
    return LocationArea(
      id: widget.areaId,
      nameAr: areaLabel,
      nameEn: areaLabel,
      imageUrl: '',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _openFilters(Map<String, LocationArea> areaNames) async {
    final areaLabel = widget.areaName.isNotEmpty
        ? widget.areaName
        : 'area_unavailable'.tr();
    final list = [areaNames[widget.areaId] ?? _fallbackArea(areaLabel)];
    await showPropertyFilterBottomSheet(
      context,
      initialFilter: _filter,
      locationAreas: list,
      onApply: (f) {
        final enforced = f.copyWith(locationAreaId: widget.areaId);
        setState(() => _filter = enforced);
        _bloc.add(CompanyPropertiesFilterChanged(enforced));
      },
      onClear: () {
        final reset = PropertyFilter(locationAreaId: widget.areaId);
        setState(() => _filter = reset);
        _bloc.add(CompanyPropertiesFilterChanged(reset));
      },
    );
  }

  void _refresh() {
    _bloc.add(CompanyPropertiesRefreshed(filter: _filter));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: _selectionMode
            ? SelectionAppBar(
                selectedCount: _selected.length,
                policy: const PropertySelectionPolicy(
                  actions: [PropertyBulkAction.share],
                ),
                actionCallbacks: {
                  PropertyBulkAction.share: () => _shareSelected(_currentItems),
                },
                onClearSelection: _clearSelection,
              )
            : CustomAppBar(
                title: widget.areaName,
                actions: [
                  BlocBuilder<CompanyPropertiesBloc, CompanyPropertiesState>(
                    builder: (context, state) {
                      final areaNames = state is CompanyPropertiesLoadSuccess
                          ? state.areaNames
                          : (state is CompanyPropertiesFailure
                                ? state.areaNames
                                : const <String, LocationArea>{});
                      return IconButton(
                        onPressed: () => _openFilters(areaNames),
                        icon: const AppSvgIcon(AppSVG.filter),
                      );
                    },
                  ),
                ],
              ),
        body: BaseGradientPage(
          child: BlocConsumer<CompanyPropertiesBloc, CompanyPropertiesState>(
            listener: (context, state) {
              if (state is CompanyPropertiesLoadSuccess) {
                _refreshController.refreshCompleted();
                if (state.hasMore) {
                  _refreshController.loadComplete();
                } else {
                  _refreshController.loadNoData();
                }
              } else if (state is CompanyPropertiesFailure) {
                _refreshController.refreshFailed();
                _refreshController.loadFailed();
              }
            },
            builder: (context, state) {
              return _CompanyAreaPropertiesList(
                state: state,
                refreshController: _refreshController,
                areaId: widget.areaId,
                areaName: widget.areaName,
                selectionMode: _selectionMode,
                selectedIds: _selected,
                onToggleSelection: _toggleSelection,
                onRefresh: _refresh,
                onRetry: () =>
                    _bloc.add(CompanyPropertiesStarted(filter: _filter)),
                onLoadMore: (lastDoc) =>
                    _bloc.add(CompanyPropertiesLoadMore(startAfter: lastDoc)),
                onItemsChanged: (items) => _currentItems = items,
                onFilterChanged: (filter) {
                  if (filter != null) {
                    _filter = filter;
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CompanyAreaPropertiesList extends StatelessWidget {
  final CompanyPropertiesState state;
  final RefreshController refreshController;
  final String areaId;
  final String areaName;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<PageToken?> onLoadMore;
  final ValueChanged<List<Property>> onItemsChanged;
  final ValueChanged<PropertyFilter?> onFilterChanged;

  const _CompanyAreaPropertiesList({
    required this.state,
    required this.refreshController,
    required this.areaId,
    required this.areaName,
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelection,
    required this.onRefresh,
    required this.onRetry,
    required this.onLoadMore,
    required this.onItemsChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final view = _CompanyAreaPropertiesView.fromState(state, areaId);
    onFilterChanged(view.filter);
    if (!view.isInitialLoading) {
      onItemsChanged(view.items);
    }

    final failure = state is CompanyPropertiesFailure
        ? state as CompanyPropertiesFailure
        : null;

    return PropertyPaginatedListView(
      refreshController: refreshController,
      items: view.items,
      isLoading: view.isInitialLoading,
      isError: state is CompanyPropertiesFailure && view.items.isEmpty,
      errorMessage: failure?.message,
      hasMore: view.hasMore,
      startAreaName: areaName,
      onRefresh: onRefresh,
      onLoadMore: () => onLoadMore(view.lastDoc),
      onRetry: onRetry,
      selectionMode: selectionMode,
      selectedIds: selectedIds,
      onToggleSelection: onToggleSelection,
      emptyMessage: 'no_properties_title'.tr(),
      emptyAction: onRetry,
    );
  }
}

class _CompanyAreaPropertiesView {
  final bool isInitialLoading;
  final List<Property> items;
  final bool hasMore;
  final PropertyFilter? filter;
  final PageToken? lastDoc;

  const _CompanyAreaPropertiesView({
    required this.isInitialLoading,
    required this.items,
    required this.hasMore,
    required this.filter,
    required this.lastDoc,
  });

  factory _CompanyAreaPropertiesView.fromState(
    CompanyPropertiesState state,
    String areaId,
  ) {
    final isInitialLoading =
        (state is CompanyPropertiesInitial ||
            state is CompanyPropertiesLoadInProgress) &&
        (state is! CompanyPropertiesLoadInProgress || state.items.isEmpty);

    final rawItems = (state is CompanyPropertiesLoadSuccess)
        ? state.items
        : (state is CompanyPropertiesLoadInProgress
              ? state.items
              : (state is CompanyPropertiesFailure
                    ? state.items
                    : const <Property>[]));

    final items = rawItems.where((p) => p.locationAreaId == areaId).toList();

    final hasMore = (state is CompanyPropertiesLoadSuccess)
        ? state.hasMore
        : (state is CompanyPropertiesLoadInProgress
              ? state.hasMore
              : (state is CompanyPropertiesLoadMoreInProgress
                    ? state.hasMore
                    : (state is CompanyPropertiesFailure
                          ? state.hasMore
                          : false)));

    final filter = (state is CompanyPropertiesLoadSuccess)
        ? state.filter
        : (state is CompanyPropertiesLoadInProgress
              ? state.filter
              : (state is CompanyPropertiesLoadMoreInProgress
                    ? state.filter
                    : (state is CompanyPropertiesFailure
                          ? state.filter
                          : null)));

    final lastDoc = (state is CompanyPropertiesLoadSuccess)
        ? state.lastDoc
        : (state is CompanyPropertiesLoadMoreInProgress
              ? state.lastDoc
              : (state is CompanyPropertiesFailure ? state.lastDoc : null));

    return _CompanyAreaPropertiesView(
      isInitialLoading: isInitialLoading,
      items: items,
      hasMore: hasMore,
      filter: filter,
      lastDoc: lastDoc,
    );
  }
}
