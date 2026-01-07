import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/components/info_card.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/usecases/get_broker_areas_usecase.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_event.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_state.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';

class BrokerAreasPage extends StatelessWidget {
  final String brokerId;
  final String? brokerName;
  const BrokerAreasPage({super.key, required this.brokerId, this.brokerName});

  @override
  Widget build(BuildContext context) {
    final title = brokerName?.isNotEmpty == true
        ? 'broker_areas_title_fmt'.tr(args: [brokerName!])
        : 'broker_areas_title'.tr();
    return Scaffold(
      appBar: CustomAppBar(title: title),
      body: BlocProvider(
        create: (context) => BrokerAreasBloc(
          context.read<GetBrokerAreasUseCase>(),
          context.read<AuthRepositoryDomain>(),
          context.read<PropertyMutationsBloc>(),
        )..add(BrokerAreasRequested(brokerId)),
        child: BlocBuilder<BrokerAreasBloc, BrokerAreasState>(
          builder: (context, state) {
            if (state is BrokerAreasInitial) {
              context.read<BrokerAreasBloc>().add(BrokerAreasRequested(brokerId));
            }
            final isLoading = state is BrokerAreasInitial || state is BrokerAreasLoadInProgress;
            if (isLoading) {
              return AppSkeletonList(
                itemCount: 6,
                itemBuilder: (_, __) => _AreaCard(name: 'loading_area'.tr(), propertyCount: 0),
              );
            }
            if (state is BrokerAreasFailure) {
              return Center(
                child: AppErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<BrokerAreasBloc>().add(BrokerAreasRequested(brokerId)),
                ),
              );
            }
            if (state is BrokerAreasLoadSuccess) {
              if (state.areas.isEmpty) {
                return EmptyStateWidget(description: 'no_locations_description'.tr());
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) {
                  final area = state.areas[i];
                  return _AreaCard(
                    name: area.name,
                    propertyCount: area.propertyCount,
                    onTap: () {
                      context.push(
                        '/broker/$brokerId/area/${area.id}',
                        extra: {'areaName': area.name, 'brokerName': brokerName ?? ''},
                      );
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: state.areas.length,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final String name;
  final int propertyCount;
  final VoidCallback? onTap;

  const _AreaCard({required this.name, required this.propertyCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: name.isNotEmpty ? name : 'area_unavailable'.tr(),
      subtitle: 'broker_areas_properties_count'.tr(args: [propertyCount.toString()]),
      icon: Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
      onTap: onTap,
    );
  }
}
