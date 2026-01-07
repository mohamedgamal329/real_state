import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/widgets/selection_app_bar.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/bloc/properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/properties_state.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/properties/presentation/utils/multi_pdf_share.dart';
import 'package:real_state/features/properties/presentation/widgets/property_paginated_list_view.dart';

class MyAddedPropertiesPage extends StatefulWidget {
  const MyAddedPropertiesPage({super.key});

  @override
  State<MyAddedPropertiesPage> createState() => _MyAddedPropertiesPageState();
}

class _MyAddedPropertiesPageState extends State<MyAddedPropertiesPage> {
  late final PropertiesBloc _bloc;
  late final RefreshController _refreshController;
  final Set<String> _selected = {};
  List<Property> _currentItems = const [];

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();

    final userId = context.read<AuthRepositoryDomain>().currentUser?.id;
    final filter = PropertyFilter(createdBy: userId);

    _bloc = PropertiesBloc(
      context.read<PropertiesRepository>(),
      context.read<LocationAreaRemoteDataSource>(),
      context.read<PropertyMutationsBloc>(),
    )..add(PropertiesStarted(filter: filter));
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: _selectionMode
            ? SelectionAppBar(
                selectedCount: _selected.length,
                onClearSelection: _clearSelection,
                onShare: _shareSelected,
              )
            : CustomAppBar(title: 'my_added_properties'.tr()),
        body: BaseGradientPage(
          child: BlocConsumer<PropertiesBloc, PropertiesState>(
            listener: (context, state) {
              if (state is PropertiesLoaded) {
                _refreshController.refreshCompleted();
                state.hasMore ? _refreshController.loadComplete() : _refreshController.loadNoData();
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
                  : (state is PropertiesActionInProgress ? state.previous : null);
              final isInitialLoading = state is PropertiesInitial || state is PropertiesLoading;

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
                onRefresh: () => _bloc.add(const PropertiesRefreshed()),
                onLoadMore: () => _bloc.add(const PropertiesLoadMoreRequested()),
                onRetry: () => _bloc.add(const PropertiesRetryRequested()),
                selectionMode: _selectionMode,
                selectedIds: _selected,
                onToggleSelection: _toggleSelection,
                emptyMessage: 'no_my_added_properties'.tr(),
              );
            },
          ),
        ),
      ),
    );
  }
}
