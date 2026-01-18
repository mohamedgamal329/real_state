import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_bloc.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_event.dart';
import 'package:real_state/features/company_areas/presentation/bloc/company_areas_state.dart';
import 'package:real_state/features/company_areas/presentation/widgets/company_area_card.dart';

class CompanyAreasPage extends StatefulWidget {
  const CompanyAreasPage({super.key});

  @override
  State<CompanyAreasPage> createState() => _CompanyAreasPageState();
}

class _CompanyAreasPageState extends State<CompanyAreasPage> {
  late final RefreshController _refreshController;

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'home_company_areas_title'.tr()),
      body: BlocConsumer<CompanyAreasBloc, CompanyAreasState>(
        listener: (context, state) {
          if (state is CompanyAreasLoadSuccess ||
              state is CompanyAreasFailure) {
            _refreshController.refreshCompleted();
            _refreshController.loadComplete();
          }
        },
        builder: (context, state) {
          final isInitialLoading =
              state is CompanyAreasInitial ||
              state is CompanyAreasLoadInProgress;

          if (state is CompanyAreasFailure) {
            return AppErrorView(
              message: state.message,
              onRetry: () => context.read<CompanyAreasBloc>().add(
                const CompanyAreasRequested(),
              ),
            );
          }

          final areas = state is CompanyAreasLoadSuccess
              ? state.areas
              : const [];

          return SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: false,
            onRefresh: () => context.read<CompanyAreasBloc>().add(
              const CompanyAreasRequested(),
            ),
            child: AppSkeletonizer(
              enabled: isInitialLoading,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  ...areas.map(
                    (area) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CompanyAreaCard(
                        area: area,
                        onTap: area.areaId.isNotEmpty
                            ? () {
                                context.push(
                                  '/company/area/${area.areaId}',
                                  extra: area.name,
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                  if (!isInitialLoading && areas.isEmpty)
                    EmptyStateWidget(description: 'no_company_areas'.tr()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
