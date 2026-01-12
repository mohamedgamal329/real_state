import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/features/properties/presentation/selection/property_selection_policy.dart';
import 'package:real_state/features/properties/presentation/selection/selection_app_bar.dart';
import 'package:real_state/features/brokers/presentation/bloc/properties/broker_area_properties_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/properties/broker_area_properties_event.dart';
import 'package:real_state/features/brokers/presentation/bloc/properties/broker_area_properties_state.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/categories/presentation/widgets/filter_bottom_sheet.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/usecases/get_broker_properties_page_usecase.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/utils/multi_pdf_share.dart';
import 'package:real_state/features/properties/presentation/widgets/property_paginated_list_view.dart';

class BrokerAreaPropertiesPage extends StatefulWidget {
  final String brokerId;
  final String areaId;
  final String? areaName;
  final String? brokerName;

  const BrokerAreaPropertiesPage({
    super.key,
    required this.brokerId,
    required this.areaId,
    this.areaName,
    this.brokerName,
  });

  @override
  State<BrokerAreaPropertiesPage> createState() => _BrokerAreaPropertiesPageState();
}

class _BrokerAreaPropertiesPageState extends State<BrokerAreaPropertiesPage> {
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
    _filter = PropertyFilter(locationAreaId: widget.areaId);
    _bloc =
        BrokerAreaPropertiesBloc(
          context.read<GetBrokerPropertiesPageUseCase>(),
          context.read<PropertyMutationsBloc>(),
          widget.brokerId,
          widget.areaId,
        )..add(
          BrokerAreaPropertiesStarted(
            brokerId: widget.brokerId,
            areaId: widget.areaId,
            filter: _filter,
          ),
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

  List<LocationArea> _locationAreasForFilter(String areaTitle) {
    return [
      LocationArea(
        id: widget.areaId,
        nameAr: areaTitle,
        nameEn: areaTitle,
        imageUrl: '',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  }

  Future<void> _openFilters(String areaTitle) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => FilterBottomSheet(
        currentFilter: _filter,
        locationAreas: _locationAreasForFilter(areaTitle),
        onAddLocation: () async {},
        onApply: (f) {
          final enforced = f.copyWith(locationAreaId: widget.areaId, clearLocationAreaId: false);
          setState(() => _filter = enforced);
          _bloc.add(BrokerAreaPropertiesFilterChanged(enforced));
        },
        onClear: () {
          final reset = PropertyFilter(locationAreaId: widget.areaId);
          setState(() => _filter = reset);
          _bloc.add(BrokerAreaPropertiesFilterChanged(reset));
        },
      ),
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
    final areaTitle = (widget.areaName?.isNotEmpty ?? false)
        ? widget.areaName!
        : 'area_unavailable'.tr();
    final brokerTitle = widget.brokerName?.isNotEmpty == true ? widget.brokerName! : '';
    final pageTitle = brokerTitle.isNotEmpty
        ? 'broker_area_properties_title_fmt'.tr(args: [brokerTitle, areaTitle])
        : areaTitle;
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: _selectionMode
            ? SelectionAppBar(
                selectedCount: _selected.length,
                policy: const PropertySelectionPolicy(actions: [PropertyBulkAction.share]),
                actionCallbacks: {
                  PropertyBulkAction.share: _shareSelected,
                },
                onClearSelection: _clearSelection,
              )
            : CustomAppBar(title: pageTitle),
        floatingActionButton: _selectionMode
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: FloatingActionButton(
                  onPressed: () => _openFilters(areaTitle),
                  child: const Icon(Icons.filter_list),
                ),
              ),
        body: BaseGradientPage(
          child: BlocConsumer<BrokerAreaPropertiesBloc, BrokerAreaPropertiesState>(
            listener: (context, state) {
              if (state is BrokerAreaPropertiesLoadSuccess) {
                _refreshController.refreshCompleted();
                if (state.hasMore) {
                  _refreshController.loadComplete();
                } else {
                  _refreshController.loadNoData();
                }
              } else if (state is BrokerAreaPropertiesFailure) {
                _refreshController.refreshFailed();
                _refreshController.loadFailed();
              }
            },
            builder: (context, state) {
              final hasCachedItems = _currentItems.isNotEmpty;
              final isInitialLoading =
                  state is BrokerAreaPropertiesInitial ||
                  (state is BrokerAreaPropertiesLoadInProgress && !hasCachedItems);

              final List<Property> items;
              if (state is BrokerAreaPropertiesLoadSuccess) {
                items = state.items;
                _hasMore = state.hasMore;
                _filter = state.filter;
              } else if (state is BrokerAreaPropertiesLoadMoreInProgress) {
                items = state.items;
                _hasMore = state.hasMore;
                _filter = state.filter;
              } else if (state is BrokerAreaPropertiesFailure) {
                items = state.items;
                _hasMore = state.hasMore;
                _filter = state.filter;
              } else {
                items = _currentItems;
              }
              if (state is BrokerAreaPropertiesLoadInProgress) {
                _filter = state.filter;
              }

              if (!isInitialLoading) {
                _currentItems = items;
              }

              return PropertyPaginatedListView(
                refreshController: _refreshController,
                items: items,
                isLoading: isInitialLoading,
                isError: state is BrokerAreaPropertiesFailure && items.isEmpty,
                errorMessage: state is BrokerAreaPropertiesFailure ? state.message : null,
                hasMore: _hasMore,
                startAreaName: areaTitle,
                onRefresh: _refresh,
                onLoadMore: () => _bloc.add(const BrokerAreaPropertiesLoadMore()),
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
