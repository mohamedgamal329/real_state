import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/selection/property_selection_controller.dart';
import 'package:real_state/core/selection/property_selection_policy.dart';
import 'package:real_state/core/selection/selection_app_bar.dart';
import 'package:real_state/core/widgets/property_filter/show_property_filter_bottom_sheet.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/lists/properties_state.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';
import 'package:real_state/core/widgets/property_paginated_list_view.dart';

class MyAddedPropertiesPage extends StatefulWidget {
  const MyAddedPropertiesPage({super.key});

  @override
  State<MyAddedPropertiesPage> createState() => _MyAddedPropertiesPageState();
}

class _MyAddedPropertiesPageState extends State<MyAddedPropertiesPage> {
  late final PropertiesBloc _bloc;
  late final RefreshController _refreshController;
  late final PropertySelectionController _selectionController;
  late final String? _userId;
  late PropertyFilter _filter;
  List<Property> _currentItems = const [];

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _selectionController = PropertySelectionController();

    _selectionController.selectedIds.addListener(_onSelectionChanged);

    _userId = context.read<AuthRepositoryDomain>().currentUser?.id;
    _filter = PropertyFilter(createdBy: _userId);

    _bloc = PropertiesBloc(
      context.read<PropertiesRepository>(),
      context.read<LocationAreasRepository>(),
      context.read<PropertyMutationsBloc>(),
    )..add(PropertiesStarted(filter: _filter));
  }

  @override
  void dispose() {
    _bloc.close();
    _refreshController.dispose();
    _selectionController.selectedIds.removeListener(_onSelectionChanged);
    _selectionController.dispose();
    super.dispose();
  }

  bool get _selectionMode => _selectionController.isSelectionActive;

  void _clearSelection() {
    _selectionController.clear();
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _shareSelected() async {
    final selectedIds = _selectionController.selectedIds.value;
    final props = _currentItems
        .where((p) => selectedIds.contains(p.id))
        .toList();
    if (props.isEmpty) return;
    await shareMultiplePropertyPdfs(context: context, properties: props);
    _clearSelection();
  }

  PropertyFilter _enforceOwner(PropertyFilter filter) {
    if (_userId == null) return filter;
    return filter.copyWith(createdBy: _userId, clearCreatedBy: false);
  }

  Future<void> _openFilters(Map<String, LocationArea> areaNames) async {
    await showPropertyFilterBottomSheet(
      context,
      initialFilter: _filter,
      locationAreas:
          null, // Allow bottom sheet to use live data from CategoriesCubit
      onApply: (filter) {
        _filter = _enforceOwner(filter);
        _bloc.add(PropertiesStarted(filter: _filter));
      },
      onClear: () {
        _filter = PropertyFilter(createdBy: _userId);
        _bloc.add(PropertiesStarted(filter: _filter));
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
                selectedCount: _selectionController.selectedCount,
                policy: const PropertySelectionPolicy(
                  actions: [PropertyBulkAction.share],
                ),
                actionCallbacks: {PropertyBulkAction.share: _shareSelected},
                onClearSelection: _clearSelection,
              )
            : CustomAppBar(
                title: 'my_added_properties'.tr(),
                actions: [
                  BlocBuilder<PropertiesBloc, PropertiesState>(
                    builder: (context, state) {
                      final areaNames = state is PropertiesLoaded
                          ? state.areaNames
                          : (state is PropertiesActionFailure
                                ? state.previous.areaNames
                                : (state is PropertiesActionSuccess
                                      ? state.previous.areaNames
                                      : const <String, LocationArea>{}));
                      return IconButton(
                        onPressed: () => _openFilters(areaNames),
                        icon: const AppSvgIcon(AppSVG.filter),
                      );
                    },
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
              }
            },
            builder: (context, state) {
              final loaded = (state is PropertiesLoaded)
                  ? state
                  : (state is PropertiesActionInProgress
                        ? state.previous
                        : null);
              final isInitialLoading =
                  state is PropertiesInitial || state is PropertiesLoading;

              final items = (loaded?.items ?? const []);
              if (!isInitialLoading) {
                _currentItems = items;
              }

              return PropertyPaginatedListView(
                refreshController: _refreshController,
                items: items,
                isLoading: isInitialLoading,
                isError: state is PropertiesFailure && items.isEmpty,
                errorMessage: state is PropertiesFailure ? state.message : null,
                hasMore: loaded?.hasMore ?? false,
                areaNames: loaded?.areaNames,
                onRefresh: () {
                  _clearSelection();
                  _bloc.add(PropertiesRefreshed(filter: _filter));
                },
                onLoadMore: () =>
                    _bloc.add(const PropertiesLoadMoreRequested()),
                onRetry: () => _bloc.add(const PropertiesRetryRequested()),
                selectionController: _selectionController,
                emptyMessage: 'no_my_added_properties'.tr(),
              );
            },
          ),
        ),
      ),
    );
  }
}
