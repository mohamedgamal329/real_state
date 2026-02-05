import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/features/location/presentation/cubit/sub_locations_cubit.dart';
import 'package:real_state/features/location/presentation/cubit/sub_locations_state.dart';
import 'package:real_state/features/models/entities/sub_location.dart';

class CompanyAreaSubLocationsPage extends StatelessWidget {
  final String areaId;
  final String areaName;

  const CompanyAreaSubLocationsPage({
    super.key,
    required this.areaId,
    required this.areaName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SubLocationsCubit(context.read())..load(areaId),
      child: Scaffold(
        appBar: CustomAppBar(
          title: areaName.isNotEmpty ? areaName : 'location_area'.tr(),
        ),
        body: BlocBuilder<SubLocationsCubit, SubLocationsState>(
          builder: (context, state) {
            if (state is SubLocationsFailure) {
              return AppErrorView(
                message: state.message,
                onRetry: () => context.read<SubLocationsCubit>().load(areaId),
              );
            }
            if (state is SubLocationsLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = state is SubLocationsLoadSuccess
                ? state.items
                : const <SubLocation>[];
            if (items.isEmpty) {
              return EmptyStateWidget(
                description: 'sub_locations_empty_desc'.tr(),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(
                    item.localizedName(localeCode: context.locale.toString()),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push(
                      '/company/area/$areaId/sub-location/${item.id}',
                      extra: item.name,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
