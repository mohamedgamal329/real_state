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

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    context.read<ArchivePropertiesBloc>().add(const ArchivePropertiesStarted());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.toString();
    return Scaffold(
      appBar: CustomAppBar(title: 'archive'),
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
              onRefresh: () =>
                  context.read<ArchivePropertiesBloc>().add(const ArchivePropertiesRefreshed()),
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

  const _ArchivedPropertyCard({
    required this.property,
    required this.areaName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700);
    return Stack(
      children: [
        PropertyCard(property: property, areaName: areaName, onTap: onTap),
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
