import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/selection/property_selection_policy.dart';
import 'package:real_state/core/selection/selection_app_bar.dart';
import 'package:real_state/core/widgets/property_filter/show_property_filter_bottom_sheet.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_state.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/properties/domain/services/property_filter_controller.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';
import 'package:real_state/core/widgets/property_paginated_list_view.dart';

class FilteredPropertiesPage extends StatefulWidget {
  final PropertyFilter filter;
  const FilteredPropertiesPage({super.key, required this.filter});

  @override
  State<FilteredPropertiesPage> createState() => _FilteredPropertiesPageState();
}

class _FilteredPropertiesPageState extends State<FilteredPropertiesPage> {
  late final PropertiesBloc _bloc;
  late final RefreshController _refreshController;
  late final PropertyFilterController _filterController;
  final Set<String> _selected = {};
  List<Property> _currentItems = const [];

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _filterController = PropertyFilterController(initial: widget.filter);
    _bloc = PropertiesBloc(
      context.read<PropertiesRepository>(),
      context.read<LocationAreasRepository>(),
      context.read<PropertyMutationsBloc>(),
    )..add(PropertiesStarted(filter: widget.filter));
  }

  @override
  void dispose() {
    _bloc.close();
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

  Future<void> _openFilters({
    required PropertyFilter currentFilter,
    required List<LocationArea> locations,
  }) async {
    await showPropertyFilterBottomSheet(
      context,
      initialFilter: currentFilter,
      locationAreas: locations,
      onApply: (filter) {
        _filterController.apply(filter);
        context.read<PropertiesBloc>().add(PropertiesStarted(filter: filter));
      },
      onClear: () {
        _filterController.clear();
        context.read<PropertiesBloc>().add(
          const PropertiesStarted(filter: PropertyFilter()),
        );
      },
    );
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
                actionCallbacks: {PropertyBulkAction.share: _shareSelected},
                onClearSelection: _clearSelection,
              )
            : CustomAppBar(
                title: 'filtered_properties'.tr(),
                actions: [
                  IconButton(
                    onPressed: () {
                      final state = _bloc.state;
                      final loaded = _loadedFrom(state);
                      final locations =
                          (loaded?.areaNames.values.toList() ??
                          const <LocationArea>[]);
                      final currentFilter =
                          loaded?.filter ?? _filterController.filter;
                      _openFilters(
                        currentFilter: currentFilter,
                        locations: locations,
                      );
                    },
                    icon: const AppSvgIcon(AppSVG.filter),
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('clear'.tr()),
                  ),
                ],
              ),
        body: BaseGradientPage(
          child: BlocConsumer<PropertiesBloc, PropertiesState>(
            listener: (context, state) {
              if (state is PropertiesLoaded) {
                _refreshController.refreshCompleted();
                state.hasMore
                    ? _refreshController.loadComplete()
                    : _refreshController.loadNoData();
              } else if (state is PropertiesFailure) {
                _refreshController.refreshFailed();
                _refreshController.loadFailed();
              } else if (state is PropertiesActionFailure) {
                _refreshController.refreshCompleted();
                state.previous.hasMore
                    ? _refreshController.loadComplete()
                    : _refreshController.loadNoData();
                final isNetwork = state.message == 'network_error'.tr();
                AppSnackbar.show(
                  context,
                  state.message,
                  type: AppSnackbarType.error,
                  actionLabel: isNetwork ? 'retry'.tr() : null,
                  onAction: isNetwork
                      ? () => context.read<PropertiesBloc>().add(
                          PropertiesRefreshed(filter: state.previous.filter),
                        )
                      : null,
                );
              }
            },
            builder: (context, state) {
              final loaded = _loadedFrom(state);
              final isInitialLoading =
                  state is PropertiesInitial || state is PropertiesLoading;

              final items = loaded?.items ?? const [];
              _currentItems = items.where((p) => p.id.isNotEmpty).toList();
              final areaNames = loaded?.areaNames ?? const {};

              return PropertyPaginatedListView(
                refreshController: _refreshController,
                items: items,
                isLoading: isInitialLoading,
                isError: state is PropertiesFailure && items.isEmpty,
                errorMessage: state is PropertiesFailure ? state.message : null,
                hasMore: loaded?.hasMore ?? false,
                areaNames: areaNames,
                onRefresh: () => context.read<PropertiesBloc>().add(
                  PropertiesRefreshed(
                    filter: loaded?.filter ?? _filterController.filter,
                  ),
                ),
                onLoadMore: () => context.read<PropertiesBloc>().add(
                  const PropertiesLoadMoreRequested(),
                ),
                onRetry: () => context.read<PropertiesBloc>().add(
                  const PropertiesRetryRequested(),
                ),
                selectionMode: _selectionMode,
                selectedIds: _selected,
                onToggleSelection: _toggleSelection,
                emptyMessage: 'no_properties_match_filters'.tr(),
                emptyAction: () => context.pop(),
              );
            },
          ),
        ),
      ),
    );
  }

  PropertiesLoaded? _loadedFrom(PropertiesState state) {
    if (state is PropertiesLoaded) return state;
    if (state is PropertiesActionInProgress) return state.previous;
    if (state is PropertiesActionFailure) return state.previous;
    if (state is PropertiesActionSuccess) return state.previous;
    return null;
  }
}
