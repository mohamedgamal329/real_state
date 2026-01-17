import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/selection/property_selection_controller.dart';
import 'package:real_state/core/selection/property_selection_policy.dart';
import 'package:real_state/core/selection/selection_app_bar.dart';
import 'package:real_state/core/utils/multi_pdf_share.dart';
import 'package:real_state/core/widgets/property_filter/show_property_filter_bottom_sheet.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/bloc/archive/archive_properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/archive/archive_properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/archive/archive_properties_state.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutation_cubit.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card.dart';
import 'package:real_state/core/widgets/property_paginated_list_view.dart';
import 'package:real_state/features/settings/presentation/pages/archive_properties/archive_properties_view.dart';
import 'package:real_state/core/constants/app_images.dart';

class ArchivePropertiesPage extends StatefulWidget {
  const ArchivePropertiesPage({super.key});

  @override
  State<ArchivePropertiesPage> createState() => _ArchivePropertiesPageState();
}

class _ArchivePropertiesPageState extends State<ArchivePropertiesPage> {
  late final RefreshController _refreshController;
  late final PropertySelectionController _selectionController;
  PropertyFilter _filter = const PropertyFilter();
  List<Property> _currentItems = const [];

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _selectionController = PropertySelectionController();
    _selectionController.selectedIds.addListener(_onSelectionChanged);
    context.read<ArchivePropertiesBloc>().add(
      ArchivePropertiesStarted(filter: _filter),
    );
  }

  @override
  void dispose() {
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

  Future<void> _openFilters(List<LocationArea> locationAreas) async {
    await showPropertyFilterBottomSheet(
      context,
      initialFilter: _filter,
      locationAreas: locationAreas,
      onApply: (filter) {
        setState(() => _filter = filter);
        context.read<ArchivePropertiesBloc>().add(
          ArchivePropertiesStarted(filter: _filter),
        );
      },
      onClear: () {
        setState(() => _filter = const PropertyFilter());
        context.read<ArchivePropertiesBloc>().add(
          ArchivePropertiesStarted(filter: _filter),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepositoryDomain>().currentUser;
    final PreferredSizeWidget appBar = _selectionMode
        ? SelectionAppBar(
            selectedCount: _selectionController.selectedCount,
            policy: const PropertySelectionPolicy(
              actions: [PropertyBulkAction.share],
            ),
            actionCallbacks: {PropertyBulkAction.share: _shareSelected},
            onClearSelection: _clearSelection,
          )
        : CustomAppBar(
            title: 'archive',
            actions: [
              BlocBuilder<ArchivePropertiesBloc, ArchivePropertiesState>(
                builder: (context, state) {
                  final loaded = _loadedFrom(state);
                  final locationAreas =
                      loaded?.areaNames.values.toList() ??
                      const <LocationArea>[];
                  return IconButton(
                    onPressed: () => _openFilters(locationAreas),
                    icon: const AppSvgIcon(AppSVG.filter),
                  );
                },
              ),
            ],
          );
    return ArchivePropertiesView(
      appBar: appBar,
      body: BlocConsumer<ArchivePropertiesBloc, ArchivePropertiesState>(
        listener: (context, state) {
          if (state is ArchivePropertiesLoaded) {
            _refreshController.refreshCompleted();
            state.hasMore
                ? _refreshController.loadComplete()
                : _refreshController.loadNoData();
          } else if (state is ArchivePropertiesActionSuccess) {
            _refreshController.refreshCompleted();
            state.previous.hasMore
                ? _refreshController.loadComplete()
                : _refreshController.loadNoData();
          } else if (state is ArchivePropertiesFailure) {
            _refreshController.refreshFailed();
            _refreshController.loadFailed();
          } else if (state is ArchivePropertiesActionFailure) {
            _refreshController.refreshCompleted();
            state.previous.hasMore
                ? _refreshController.loadComplete()
                : _refreshController.loadNoData();
          }
        },
        builder: (context, state) {
          final loaded = _loadedFrom(state);
          final isInitialLoading =
              state is ArchivePropertiesInitial ||
              state is ArchivePropertiesLoading;
          final items = loaded?.items ?? const [];
          final areaNames = loaded?.areaNames ?? const {};
          final errorMessage = state is ArchivePropertiesFailure
              ? state.message
              : null;

          if (!isInitialLoading) {
            _currentItems = items;
          }

          return _ArchivePropertiesList(
            refreshController: _refreshController,
            selectionController: _selectionController,
            items: items,
            areaNames: areaNames,
            currentUser: currentUser,
            hasMore: loaded?.hasMore ?? false,
            isLoading: isInitialLoading,
            isError: state is ArchivePropertiesFailure && items.isEmpty,
            errorMessage: errorMessage,
            filter: _filter,
            onRefresh: () {
              _clearSelection();
              context.read<ArchivePropertiesBloc>().add(
                ArchivePropertiesRefreshed(filter: _filter),
              );
            },
            onLoadMore: () => context.read<ArchivePropertiesBloc>().add(
              const ArchivePropertiesLoadMoreRequested(),
            ),
            onRetry: () => context.read<ArchivePropertiesBloc>().add(
              const ArchivePropertiesRetryRequested(),
            ),
          );
        },
      ),
    );
  }

  ArchivePropertiesLoaded? _loadedFrom(ArchivePropertiesState state) {
    if (state is ArchivePropertiesLoaded) return state;
    if (state is ArchivePropertiesActionInProgress) return state.previous;
    if (state is ArchivePropertiesActionFailure) return state.previous;
    if (state is ArchivePropertiesActionSuccess) return state.previous;
    return null;
  }
}

class _ArchivePropertiesList extends StatelessWidget {
  final RefreshController refreshController;
  final PropertySelectionController selectionController;
  final List<Property> items;
  final Map<String, LocationArea> areaNames;
  final UserEntity? currentUser;
  final bool hasMore;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final PropertyFilter filter;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  const _ArchivePropertiesList({
    required this.refreshController,
    required this.selectionController,
    required this.items,
    required this.areaNames,
    required this.currentUser,
    required this.hasMore,
    required this.isLoading,
    required this.isError,
    required this.errorMessage,
    required this.filter,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PropertyPaginatedListView(
      refreshController: refreshController,
      items: items,
      isLoading: isLoading,
      isError: isError,
      errorMessage: errorMessage,
      hasMore: hasMore,
      areaNames: areaNames,
      onRefresh: onRefresh,
      onLoadMore: onLoadMore,
      onRetry: onRetry,
      selectionController: selectionController,
      emptyMessage: 'no_properties_archive'.tr(),
      emptyAction: () => context.read<ArchivePropertiesBloc>().add(
        ArchivePropertiesStarted(filter: filter),
      ),
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
            _,
          ) {
            final canNavigate = property.id.isNotEmpty && !selectionMode;
            final canRestore =
                !selectionMode &&
                currentUser != null &&
                property.createdBy == currentUser!.id;
            return _ArchivedPropertyCard(
              property: property,
              areaName: areaName,
              onTap: canNavigate
                  ? () => context.push(
                      '/property/${property.id}',
                      extra: {'readOnly': true},
                    )
                  : onSelectToggle,
              selectionMode: selectionMode,
              selected: selected,
              onSelectToggle: onSelectToggle,
              onLongPressSelect: onLongPressSelect,
              canRestore: canRestore,
              onRestore: canRestore
                  ? () => _restoreProperty(context, property)
                  : null,
            );
          },
    );
  }

  Future<void> _restoreProperty(BuildContext context, Property property) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await LoadingDialog.show(
        context,
        context.read<PropertyMutationCubit>().restore(
          property: property,
          userId: user.id,
          userRole: user.role,
        ),
      );
      if (!context.mounted) return;
      AppSnackbar.show(context, 'property_restored_success'.tr());
    } catch (e, st) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        mapErrorMessage(e, stackTrace: st),
        type: AppSnackbarType.error,
      );
    }
  }
}

class _ArchivedPropertyCard extends StatelessWidget {
  final Property property;
  final String areaName;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPressSelect;
  final bool canRestore;
  final VoidCallback? onRestore;

  const _ArchivedPropertyCard({
    required this.property,
    required this.areaName,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    this.onLongPressSelect,
    this.canRestore = false,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700);
    return Stack(
      children: [
        PropertyCard(
          property: property,
          areaName: areaName,
          onTap: onTap,
          selectionMode: selectionMode,
          selected: selected,
          onSelectToggle: onSelectToggle,
          onLongPressSelect: onLongPressSelect,
        ),
        Positioned(
          top: 8,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('archive'.tr(), style: textStyle),
          ),
        ),
        if (canRestore && onRestore != null)
          Positioned.directional(
            textDirection: Directionality.of(context),
            bottom: 10,
            end: 12,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onRestore,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    'restore'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
