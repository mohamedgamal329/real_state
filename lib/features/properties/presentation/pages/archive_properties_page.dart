import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/features/properties/presentation/selection/property_selection_controller.dart';
import 'package:real_state/features/properties/presentation/selection/property_selection_policy.dart';
import 'package:real_state/features/properties/presentation/selection/selection_app_bar.dart';
import 'package:real_state/features/properties/presentation/utils/multi_pdf_share.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/widgets/property_list_scaffold.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/presentation/bloc/archive_properties_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/archive_properties_event.dart';
import 'package:real_state/features/properties/presentation/bloc/archive_properties_state.dart';
import 'package:real_state/features/properties/presentation/utils/property_placeholders.dart';
import 'package:real_state/features/properties/presentation/widgets/property_card.dart';

class ArchivePropertiesPage extends StatefulWidget {
  const ArchivePropertiesPage({super.key});

  @override
  State<ArchivePropertiesPage> createState() => _ArchivePropertiesPageState();
}

class _ArchivePropertiesPageState extends State<ArchivePropertiesPage> {
  late final RefreshController _refreshController;
  late final PropertySelectionController _selectionController;
  List<Property> _currentItems = const [];

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _selectionController = PropertySelectionController();
    _selectionController.selectedIds.addListener(_onSelectionChanged);
    context.read<ArchivePropertiesBloc>().add(const ArchivePropertiesStarted());
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

  void _toggleSelection(String id) {
    _selectionController.toggle(id);
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _shareSelected() async {
    final selectedIds = _selectionController.selectedIds.value;
    final props = _currentItems.where((p) => selectedIds.contains(p.id)).toList();
    if (props.isEmpty) return;
    await shareMultiplePropertyPdfs(context: context, properties: props);
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.toString();
    return Scaffold(
      appBar: _selectionMode
          ? SelectionAppBar(
              selectedCount: _selectionController.selectedCount,
              policy: const PropertySelectionPolicy(actions: [PropertyBulkAction.share]),
              actionCallbacks: {
                PropertyBulkAction.share: _shareSelected,
              },
              onClearSelection: _clearSelection,
            )
          : CustomAppBar(title: 'archive'),
      body: BaseGradientPage(
        child: BlocConsumer<ArchivePropertiesBloc, ArchivePropertiesState>(
          listener: (context, state) {
            if (state is ArchivePropertiesLoaded) {
              _refreshController.refreshCompleted();
              state.hasMore ? _refreshController.loadComplete() : _refreshController.loadNoData();
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
                state is ArchivePropertiesInitial || state is ArchivePropertiesLoading;

            if (state is ArchivePropertiesFailure) {
              return AppErrorView(
                message: state.message,
                onRetry: () => context.read<ArchivePropertiesBloc>().add(
                  const ArchivePropertiesRetryRequested(),
                ),
              );
            }

            final items = isInitialLoading ? placeholderProperties() : (loaded?.items ?? const []);
            final areaNames = loaded?.areaNames ?? const {};

            if (!isInitialLoading) {
              _currentItems = items;
            }

            if (!isInitialLoading && items.isEmpty) {
              return EmptyStateWidget(
                description: 'no_properties_archive'.tr(),
                action: () {
                  context.read<ArchivePropertiesBloc>().add(const ArchivePropertiesStarted());
                },
              );
            }

            return PropertyListScaffold(
              controller: _refreshController,
              isInitialLoading: isInitialLoading,
              hasMore: loaded?.hasMore ?? false,
              onRefresh: () {
                _clearSelection();
                context.read<ArchivePropertiesBloc>().add(const ArchivePropertiesRefreshed());
              },
              onLoadMore: () => context.read<ArchivePropertiesBloc>().add(
                const ArchivePropertiesLoadMoreRequested(),
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final property = items[index];
                final areaName =
                    areaNames[property.locationAreaId]?.localizedName(localeCode: localeCode) ??
                    'placeholder_dash'.tr();
                return _ArchivedPropertyCard(
                  property: property,
                  areaName: areaName,
                  onTap: () => context.push('/property/${property.id}', extra: {'readOnly': true}),
                  selectionMode: _selectionMode,
                  selected: _selectionController.isSelected(property.id),
                  onSelectToggle: () => _toggleSelection(property.id),
                  onLongPressSelect: () => _toggleSelection(property.id),
                );
              },
            );
          },
        ),
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

class _ArchivedPropertyCard extends StatelessWidget {
  final Property property;
  final String areaName;
  final VoidCallback onTap;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectToggle;
  final VoidCallback? onLongPressSelect;

  const _ArchivedPropertyCard({
    required this.property,
    required this.areaName,
    required this.onTap,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectToggle,
    this.onLongPressSelect,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700);
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
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(10)),
            child: Text('archive'.tr(), style: textStyle),
          ),
        ),
      ],
    );
  }
}
