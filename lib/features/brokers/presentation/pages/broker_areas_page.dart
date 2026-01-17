import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/widgets/location_area_card.dart';
import 'package:real_state/features/brokers/presentation/controller/broker_areas_controller.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_event.dart';
import 'package:real_state/features/brokers/presentation/bloc/areas/broker_areas_state.dart';
import 'package:real_state/features/models/entities/location_area.dart';

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
        create: (context) =>
            context.read<BrokerAreasController>().createBloc(brokerId),
        child: BlocBuilder<BrokerAreasBloc, BrokerAreasState>(
          builder: (context, state) {
            final isLoading =
                state is BrokerAreasInitial ||
                state is BrokerAreasLoadInProgress;
            if (isLoading) {
              return AppSkeletonList(
                itemCount: 6,
                itemBuilder: (_, __) => _AreaCard(
                  area: _placeholderArea('loading_area'.tr()),
                  propertyCount: 0,
                ),
              );
            }
            if (state is BrokerAreasFailure) {
              return Center(
                child: AppErrorView(
                  message: state.message,
                  onRetry: () => context.read<BrokerAreasBloc>().add(
                    BrokerAreasRequested(brokerId),
                  ),
                ),
              );
            }
            if (state is BrokerAreasLoadSuccess) {
              if (state.areas.isEmpty) {
                return EmptyStateWidget(
                  description: 'no_locations_description'.tr(),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (_, i) {
                  final area = state.areas[i];
                  final detail = state.areaDetails[area.id];
                  return _AreaCard(
                    area:
                        detail ??
                        LocationArea(
                          id: area.id,
                          nameAr: area.name,
                          nameEn: area.name,
                          imageUrl: '',
                          isActive: true,
                          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                        ),
                    propertyCount: area.propertyCount,
                    onTap: () {
                      context.push(
                        '/broker/$brokerId/area/${area.id}',
                        extra: {
                          'areaName': area.name,
                          'brokerName': brokerName ?? '',
                        },
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
  final LocationArea area;
  final int propertyCount;
  final VoidCallback? onTap;

  const _AreaCard({
    required this.area,
    required this.propertyCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LocationAreaCard(
      area: area,
      localeCode: context.locale.toString(),
      footer: 'broker_areas_properties_count'.tr(
        args: [propertyCount.toString()],
      ),
      onTap: onTap,
    );
  }
}

LocationArea _placeholderArea(String name) {
  return LocationArea(
    id: '',
    nameAr: name,
    nameEn: name,
    imageUrl: '',
    isActive: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}
