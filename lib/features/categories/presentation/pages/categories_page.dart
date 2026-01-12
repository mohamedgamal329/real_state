import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/widgets/property_list_scaffold.dart';
import 'package:real_state/features/properties/presentation/selection/property_selection_policy.dart';
import 'package:real_state/features/properties/presentation/selection/selection_app_bar.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:real_state/features/categories/presentation/cubit/categories_state.dart';
import 'package:real_state/features/categories/presentation/widgets/category_property_card.dart';
import 'package:real_state/features/properties/presentation/utils/property_placeholders.dart';
import 'package:real_state/features/properties/presentation/utils/multi_pdf_share.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _selectionMode
          ? SelectionAppBar(
              selectedCount: _selected.length,
              policy: const PropertySelectionPolicy(actions: [PropertyBulkAction.share]),
              actionCallbacks: {
                PropertyBulkAction.share: _shareSelected,
              },
              onClearSelection: _clearSelection,
            )
          : CustomAppBar(title: 'categories'.tr()),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () {
            final cubit = context.read<CategoriesCubit>();
            context.push('/filters/categories', extra: cubit);
          },
          child: const Icon(Icons.filter_list),
        ),
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
            final core = state as CategoriesCoreState;
            final dataState = state is CategoriesListState ? state : null;
            final isInitialLoading =
                state is CategoriesInitial || state is CategoriesLoadInProgress;

            if (state is CategoriesFailure ||
                (state is CategoriesPartialFailure && state.items.isEmpty)) {
              final message = state is CategoriesFailure
                  ? state.message
                  : (state as CategoriesPartialFailure).message;
              return AppErrorView(
                message: message,
                onRetry: () => context.read<CategoriesCubit>().loadFirstPage(),
              );
            }

            final items = isInitialLoading
                ? placeholderProperties()
                : (dataState?.items ?? const []);
            _currentItems = items.where((p) => p.id.isNotEmpty).toList();

            if (!isInitialLoading && items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmptyStateWidget(
                      description: 'no_properties_title'.tr(),
                      action: () =>
                          context.read<CategoriesCubit>().loadFirstPage(),
                    ),
                    const SizedBox(height: 16),
                    if (!core.filter.isEmpty)
                      TextButton(
                        onPressed: () =>
                            context.read<CategoriesCubit>().clearFilters(),
                        child: Text('clear_filters'.tr()),
                      ),
                  ],
                ),
              );
            }

            return PropertyListScaffold(
              controller: _refreshController,
              isInitialLoading: isInitialLoading,
              hasMore: dataState?.hasMore ?? false,
              onRefresh: () => context.read<CategoriesCubit>().refresh(),
              onLoadMore: () => context.read<CategoriesCubit>().loadMore(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final property = items[index];
                final localeCode = context.locale.toString();
                return CategoryPropertyCard(
                  property: property,
                    areaName: core.areaNames[property.locationAreaId]
                            ?.localizedName(localeCode: localeCode) ??
                        'placeholder_dash'.tr(),
                  selectionMode: _selectionMode,
                  selected: _selected.contains(property.id),
                  onSelectToggle: () => _toggleSelection(property.id),
                  onLongPressSelect: () => _toggleSelection(property.id),
                  onTap: _selectionMode
                      ? () => _toggleSelection(property.id)
                      : () => GoRouter.of(context)
                          .push('/property/${property.id}'),
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
