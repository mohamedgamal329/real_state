import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/features/properties/presentation/selection/property_selection_policy.dart';
import 'package:real_state/features/properties/presentation/selection/selection_app_bar.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/categories/presentation/widgets/filter_bottom_sheet.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/bloc/company_properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/company_properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/company_properties_state.dart';
import 'package:real_state/features/properties/presentation/utils/multi_pdf_share.dart';
import 'package:real_state/features/properties/presentation/widgets/property_paginated_list_view.dart';

class CompanyAreaPropertiesPage extends StatefulWidget {
  final String areaId;
  final String areaName;

  const CompanyAreaPropertiesPage({super.key, required this.areaId, required this.areaName});

  @override
  State<CompanyAreaPropertiesPage> createState() => _CompanyAreaPropertiesPageState();
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
    _bloc = CompanyPropertiesBloc(context.read(), context.read(), context.read())
      ..add(CompanyPropertiesStarted(filter: _filter));
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
    final selectedProps = properties.where((p) => _selected.contains(p.id)).toList();
    if (selectedProps.isEmpty) return;
    await shareMultiplePropertyPdfs(context: context, properties: selectedProps);
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
    final areaLabel = widget.areaName.isNotEmpty ? widget.areaName : 'area_unavailable'.tr();
    final list = [areaNames[widget.areaId] ?? _fallbackArea(areaLabel)];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FilterBottomSheet(
        currentFilter: _filter,
        locationAreas: list,
        onAddLocation: () async {},
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
      ),
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
                policy: const PropertySelectionPolicy(actions: [PropertyBulkAction.share]),
                actionCallbacks: {
                  PropertyBulkAction.share: () => _shareSelected(_currentItems),
                },
                onClearSelection: _clearSelection,
              )
            : CustomAppBar(title: widget.areaName),
        floatingActionButton: _selectionMode
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: BlocBuilder<CompanyPropertiesBloc, CompanyPropertiesState>(
                  builder: (context, state) {
                    final areaNames = state is CompanyPropertiesLoadSuccess
                        ? state.areaNames
                        : (state is CompanyPropertiesFailure
                              ? state.areaNames
                              : const <String, LocationArea>{});
                    return FloatingActionButton(
                      onPressed: () => _openFilters(areaNames),
                      child: const Icon(Icons.filter_list),
                    );
                  },
                ),
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
              final isInitialLoading =
                  (state is CompanyPropertiesInitial || state is CompanyPropertiesLoadInProgress) &&
                  (state is! CompanyPropertiesLoadInProgress || state.items.isEmpty);

              final rawItems = (state is CompanyPropertiesLoadSuccess)
                  ? state.items
                  : (state is CompanyPropertiesLoadInProgress
                        ? state.items
                        : (state is CompanyPropertiesFailure ? state.items : const <Property>[]));

              final items = rawItems.where((p) => p.locationAreaId == widget.areaId).toList();

              if (!isInitialLoading) {
                _currentItems = items;
              }

              final hasMore = (state is CompanyPropertiesLoadSuccess)
                  ? state.hasMore
                  : (state is CompanyPropertiesLoadInProgress
                        ? state.hasMore
                        : (state is CompanyPropertiesLoadMoreInProgress
                              ? state.hasMore
                              : (state is CompanyPropertiesFailure ? state.hasMore : false)));

              final stateFilter = (state is CompanyPropertiesLoadSuccess)
                  ? state.filter
                  : (state is CompanyPropertiesLoadInProgress
                        ? state.filter
                        : (state is CompanyPropertiesLoadMoreInProgress
                              ? state.filter
                              : (state is CompanyPropertiesFailure ? state.filter : null)));
              if (stateFilter != null) {
                _filter = stateFilter;
              }

              return PropertyPaginatedListView(
                refreshController: _refreshController,
                items: items,
                isLoading: isInitialLoading,
                isError: state is CompanyPropertiesFailure && items.isEmpty,
                errorMessage: state is CompanyPropertiesFailure ? state.message : null,
                hasMore: hasMore,
                startAreaName: widget.areaName,
                onRefresh: _refresh,
                onLoadMore: () {
                  final lastDoc = (state is CompanyPropertiesLoadSuccess)
                      ? state.lastDoc
                      : (state is CompanyPropertiesLoadMoreInProgress
                            ? state.lastDoc
                            : (state is CompanyPropertiesFailure ? state.lastDoc : null));
                  _bloc.add(CompanyPropertiesLoadMore(startAfter: lastDoc));
                },
                onRetry: () => _bloc.add(CompanyPropertiesStarted(filter: _filter)),
                selectionMode: _selectionMode,
                selectedIds: _selected,
                onToggleSelection: _toggleSelection,
                emptyMessage: 'no_properties_title'.tr(),
                emptyAction: () => _bloc.add(CompanyPropertiesStarted(filter: _filter)),
              );
            },
          ),
        ),
      ),
    );
  }
}
