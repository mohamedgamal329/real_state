import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/selection/property_selection_policy.dart';
import 'package:real_state/core/selection/selection_app_bar.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/core/widgets/property_filter/show_property_filter_bottom_sheet.dart';
import 'package:real_state/features/brokers/presentation/controller/broker_area_properties_controller.dart';
import 'package:real_state/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_bloc.dart';
import 'package:real_state/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_event.dart';
import 'package:real_state/features/brokers/presentation/pages/broker_area_properties/broker_area_properties_state.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';
import 'package:real_state/core/widgets/property_paginated_list_view.dart';

class BrokerAreaSubLocationPropertiesPage extends StatefulWidget {
  final String brokerId;
  final String areaId;
  final String areaName;
  final String brokerName;
  final String subLocationId;
  final String subLocationName;

  const BrokerAreaSubLocationPropertiesPage({
    super.key,
    required this.brokerId,
    required this.areaId,
    required this.areaName,
    required this.brokerName,
    required this.subLocationId,
    required this.subLocationName,
  });

  @override
  State<BrokerAreaSubLocationPropertiesPage> createState() =>
      _BrokerAreaSubLocationPropertiesPageState();
}

class _BrokerAreaSubLocationPropertiesPageState
    extends State<BrokerAreaSubLocationPropertiesPage> {
  late final BrokerAreaPropertiesBloc _bloc;
  late final RefreshController _refreshController;
  final Set<String> _selected = {};
  List<Property> _currentItems = const [];
  bool _hasMore = false;
  late PropertyFilter _filter;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _filter = PropertyFilter(
      locationAreaId: widget.areaId,
      subLocationId: widget.subLocationId,
    );
    _bloc = context.read<BrokerAreaPropertiesController>().createBloc(
      brokerId: widget.brokerId,
      areaId: widget.areaId,
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

  Future<void> _shareSelected() async {
    final props = _currentItems.where((p) => _selected.contains(p.id)).toList();
    if (props.isEmpty) return;
    await shareMultiplePropertyPdfs(context: context, properties: props);
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

  Future<void> _openFilters(String areaTitle) async {
    await showPropertyFilterBottomSheet(
      context,
      initialFilter: _filter,
      locationAreas: [_fallbackArea(areaTitle)],
      onApply: (f) {
        final enforced = f.copyWith(
          locationAreaId: widget.areaId,
          subLocationId: widget.subLocationId,
        );
        setState(() => _filter = enforced);
        _bloc.add(BrokerAreaPropertiesFilterChanged(enforced));
      },
      onClear: () {
        final reset = PropertyFilter(
          locationAreaId: widget.areaId,
          subLocationId: widget.subLocationId,
        );
        setState(() => _filter = reset);
        _bloc.add(BrokerAreaPropertiesFilterChanged(reset));
      },
    );
  }

  void _refresh() {
    _bloc.add(
      BrokerAreaPropertiesRefreshed(
        brokerId: widget.brokerId,
        areaId: widget.areaId,
        filter: _filter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final areaTitle = widget.areaName.isNotEmpty
        ? widget.areaName
        : 'area_unavailable'.tr();
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
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
                title: widget.subLocationName.isNotEmpty
                    ? widget.subLocationName
                    : 'sub_location'.tr(),
                actions: [
                  IconButton(
                    onPressed: () => _openFilters(areaTitle),
                    icon: const AppSvgIcon(AppSVG.filter),
                  ),
                ],
              ),
        body: BaseGradientPage(
          child:
              BlocConsumer<BrokerAreaPropertiesBloc, BrokerAreaPropertiesState>(
                listener: (context, state) {
                  if (state is BrokerAreaPropertiesLoadSuccess) {
                    _refreshController.refreshCompleted();
                    _currentItems = state.items;
                    _filter = state.filter;
                    _hasMore = state.hasMore;
                    if (state.hasMore) {
                      _refreshController.loadComplete();
                    } else {
                      _refreshController.loadNoData();
                    }
                  } else if (state is BrokerAreaPropertiesLoadMoreInProgress) {
                    _currentItems = state.items;
                    _filter = state.filter;
                    _hasMore = state.hasMore;
                  } else if (state is BrokerAreaPropertiesFailure) {
                    _refreshController.refreshFailed();
                    _refreshController.loadFailed();
                    _currentItems = state.items;
                    _filter = state.filter;
                    _hasMore = state.hasMore;
                  } else if (state is BrokerAreaPropertiesLoadInProgress) {
                    _filter = state.filter;
                  }
                },
                builder: (context, state) {
                  final view = _BrokerAreaSubLocationPropertiesView.fromState(
                    state,
                    cachedItems: _currentItems,
                    cachedFilter: _filter,
                    cachedHasMore: _hasMore,
                  );

                  return PropertyPaginatedListView(
                    refreshController: _refreshController,
                    items: view.items,
                    isLoading: view.isInitialLoading,
                    isError: state is BrokerAreaPropertiesFailure &&
                        view.items.isEmpty,
                    errorMessage: state is BrokerAreaPropertiesFailure
                        ? state.message
                        : null,
                    hasMore: view.hasMore,
                    startAreaName: areaTitle,
                    onRefresh: _refresh,
                    onLoadMore: () =>
                        _bloc.add(const BrokerAreaPropertiesLoadMore()),
                    onRetry: _refresh,
                    selectionMode: _selectionMode,
                    selectedIds: _selected,
                    onToggleSelection: _toggleSelection,
                    emptyMessage: 'no_broker_properties_in_area'.tr(),
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _BrokerAreaSubLocationPropertiesView {
  final bool isInitialLoading;
  final List<Property> items;
  final PropertyFilter filter;
  final bool hasMore;

  const _BrokerAreaSubLocationPropertiesView({
    required this.isInitialLoading,
    required this.items,
    required this.filter,
    required this.hasMore,
  });

  factory _BrokerAreaSubLocationPropertiesView.fromState(
    BrokerAreaPropertiesState state, {
    required List<Property> cachedItems,
    required PropertyFilter cachedFilter,
    required bool cachedHasMore,
  }) {
    final hasCachedItems = cachedItems.isNotEmpty;
    final isInitialLoading =
        state is BrokerAreaPropertiesInitial ||
        (state is BrokerAreaPropertiesLoadInProgress && !hasCachedItems);

    List<Property> items = cachedItems;
    var filter = cachedFilter;
    var hasMore = cachedHasMore;

    if (state is BrokerAreaPropertiesLoadSuccess) {
      items = state.items;
      hasMore = state.hasMore;
      filter = state.filter;
    } else if (state is BrokerAreaPropertiesLoadMoreInProgress) {
      items = state.items;
      hasMore = state.hasMore;
      filter = state.filter;
    } else if (state is BrokerAreaPropertiesFailure) {
      items = state.items;
      hasMore = state.hasMore;
      filter = state.filter;
    } else if (state is BrokerAreaPropertiesLoadInProgress) {
      filter = state.filter;
    }

    return _BrokerAreaSubLocationPropertiesView(
      isInitialLoading: isInitialLoading,
      items: items,
      filter: filter,
      hasMore: hasMore,
    );
  }
}
