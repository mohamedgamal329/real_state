import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/components/info_card.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_event.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_state.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_bloc.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_event.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_state.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late RefreshController _refreshController;

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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'home',
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Image.asset('assets/images/logo.jpeg', height: 26),
          ),
        ],
      ),
      body: StreamBuilder<UserEntity?>(
        stream: context.read<AuthRepositoryDomain>().userChanges,
        builder: (context, snapshot) {
          final role = snapshot.data?.role;
          final showBrokers = role != null && canSeeBrokersSection(role);
          return BaseGradientPage(
            child: BlocConsumer<CompanyAreasBloc, CompanyAreasState>(
              listener: (context, state) {
                if (state is CompanyAreasLoadSuccess || state is CompanyAreasFailure) {
                  _refreshController.refreshCompleted();
                  _refreshController.loadComplete();
                }
              },
              builder: (context, state) {
                final areas = state is CompanyAreasLoadSuccess
                    ? state.areas
                    : (state is CompanyAreasLoadInProgress ? state.areas : const []);

                final isInitialLoading =
                    (state is CompanyAreasInitial || state is CompanyAreasLoadInProgress) &&
                    areas.isEmpty;
                final hasError = state is CompanyAreasFailure;
                final errorMessage = state is CompanyAreasFailure ? state.message : null;

                return SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  enablePullUp: false,
                  onRefresh: () =>
                      context.read<CompanyAreasBloc>().add(const CompanyAreasRequested()),
                  child: AppSkeletonizer(
                    enabled: isInitialLoading,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        InfoCard(
                          title: 'company_properties_title'.tr(),
                          icon: Icon(
                            Icons.domain_add,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onTap: () => context.push(
                            '/company/areas',
                            extra: context.read<CompanyAreasBloc>(),
                          ),
                        ),
                        if (hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: AppErrorView(
                              message: errorMessage ?? '',
                              onRetry: () => context.read<CompanyAreasBloc>().add(
                                const CompanyAreasRequested(),
                              ),
                            ),
                          )
                        else if (!isInitialLoading && areas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: EmptyStateWidget(description: 'no_company_areas'.tr()),
                          ),
                        if (showBrokers) ...[const SizedBox(height: 12), _BrokersSection()],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: StreamBuilder<UserEntity?>(
        stream: context.read<AuthRepositoryDomain>().userChanges,
        builder: (context, snapshot) {
          final role = snapshot.data?.role;
          if (role == null || !canCreateProperty(role)) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FloatingActionButton(
              onPressed: () async {
                await context.push('/property/new');
              },
              heroTag: 'properties_fab',
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}

class _BrokersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BrokersListBloc, BrokersListState>(
      builder: (context, state) {
        if (state is BrokersListInitial) {
          context.read<BrokersListBloc>().add(const BrokersListRequested());
          return const _BrokersSkeleton(showHeader: true);
        }
        final brokers = state is BrokersListLoadSuccess
            ? state.brokers
            : (state is BrokersListLoadInProgress ? state.brokers : const []);

        if (state is BrokersListLoadInProgress && brokers.isEmpty) {
          return const _BrokersSkeleton(showHeader: true);
        }
        if (state is BrokersListFailure) {
          return AppErrorView(
            message: state.message,
            onRetry: () => context.read<BrokersListBloc>().add(const BrokersListRequested()),
          );
        }
        if (brokers.isEmpty) {
          return EmptyStateWidget(description: 'brokers_empty_desc'.tr());
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.people_alt_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'home_brokers_section_title'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            ...brokers.map(
              (b) => Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      Characters(
                        b.name?.isNotEmpty == true
                            ? b.name!
                            : (b.email ?? 'broker_unknown_name'.tr()),
                      ).take(2).toString().toUpperCase(),
                    ),
                  ),
                  title: Text(
                    b.name?.isNotEmpty == true ? b.name! : (b.email ?? 'broker_unknown_name'.tr()),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/broker/${b.id}/areas', extra: {'name': b.name ?? b.email ?? ''});
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BrokersSkeleton extends StatelessWidget {
  final bool showHeader;
  const _BrokersSkeleton({this.showHeader = false});

  @override
  Widget build(BuildContext context) {
    final list = AppSkeletonList(
      itemCount: 3,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 10),
        child: const ListTile(
          leading: CircleAvatar(),
          title: SizedBox(height: 12, child: ColoredBox(color: Colors.transparent)),
          subtitle: SizedBox(height: 10, child: ColoredBox(color: Colors.transparent)),
        ),
      ),
    );

    if (!showHeader) return list;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: AppSkeletonizer(
            enabled: true,
            child: Container(
              height: 16,
              width: 120,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        list,
      ],
    );
  }
}
