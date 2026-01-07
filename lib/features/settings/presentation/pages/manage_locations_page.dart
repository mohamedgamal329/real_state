import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/animations/slide_fade_in.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/location/data/repositories/location_repository.dart';
import 'package:real_state/features/location/domain/usecases/get_location_areas_usecase.dart';
import 'package:real_state/features/location/presentation/widgets/location_area_card.dart';
import 'package:real_state/features/location/presentation/widgets/location_area_form_dialog.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_locations_cubit.dart';

class ManageLocationsPage extends StatelessWidget {
  const ManageLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ManageLocationsCubit(
        context.read<LocationRepository>(),
        context.read<AuthRepositoryDomain>(),
        context.read<GetLocationAreasUseCase>(),
      )..initialize(),
      child: const _ManageLocationsView(),
    );
  }
}

class _ManageLocationsView extends StatefulWidget {
  const _ManageLocationsView();

  @override
  State<_ManageLocationsView> createState() => _ManageLocationsViewState();
}

class _ManageLocationsViewState extends State<_ManageLocationsView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageLocationsCubit, ManageLocationsState>(
      listener: (context, state) {
        if (state is ManageLocationsFailure) {
          AppSnackbar.show(context, state.message, isError: true);
        } else if (state is ManageLocationsPartialFailure) {
          AppSnackbar.show(context, state.message, isError: true);
        } else if (state is ManageLocationsAccessDenied) {
          AppSnackbar.show(context, state.message, isError: true);
        }
      },
      builder: (context, state) {
        if (state is ManageLocationsAccessDenied) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'manage_locations'),
            body: AppErrorView(
              message: state.message,
              onRetry: () => context.read<ManageLocationsCubit>().initialize(),
            ),
          );
        }

        if (state is ManageLocationsFailure && state is! ManageLocationsDataState) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'manage_locations'),
            body: AppErrorView(
              message: state.message,
              onRetry: () => context.read<ManageLocationsCubit>().initialize(),
            ),
          );
        }

        final dataState = state is ManageLocationsDataState ? state : null;
        final showSkeleton =
            state is ManageLocationsCheckingAccess || state is ManageLocationsLoadInProgress;

        if (showSkeleton) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'manage_locations'),
            body: AppSkeletonList(
              itemBuilder: (_, __) => LocationAreaCard(
                area: _placeholderLocations()[0],
                localeCode: context.locale.toString(),
              ),
            ),
          );
        }

        final items = dataState?.items ?? [];
        final canInteract = dataState != null && state is! ManageLocationsActionInProgress;

        return Scaffold(
          appBar: const CustomAppBar(title: 'manage_locations'),
          body: items.isEmpty
              ? EmptyStateWidget(
                  description: 'no_locations_description'.tr(),
                  action: () => _create(context.read<ManageLocationsCubit>()),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (c, i) {
                    final it = items[i];
                    return SlideFadeIn(
                      delay: Duration(milliseconds: 40 * i),
                      child: LocationAreaCard(
                        area: it,
                        localeCode: context.locale.toString(),
                        onEdit: canInteract && _isAreaComplete(it)
                            ? () => _edit(context.read<ManageLocationsCubit>(), it)
                            : null,
                        onDelete: canInteract && _isAreaComplete(it)
                            ? () => _delete(context.read<ManageLocationsCubit>(), it)
                            : null,
                      ),
                    );
                  },
                ),

          floatingActionButton: FloatingActionButton(
            onPressed: () => _create(context.read<ManageLocationsCubit>()),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _create(ManageLocationsCubit cubit) async {
    final res = await LocationAreaFormDialog.show(context);
    if (res == null || res.imageFile == null) return;
    await LoadingDialog.show(
      context,
      cubit.create(nameAr: res.nameAr, nameEn: res.nameEn, imageFile: res.imageFile!),
    );
  }

  Future<void> _edit(ManageLocationsCubit cubit, LocationArea item) async {
    final res = await LocationAreaFormDialog.show(context, initial: item);
    if (res == null) return;
    await LoadingDialog.show(
      context,
      cubit.update(item, nameAr: res.nameAr, nameEn: res.nameEn, imageFile: res.imageFile),
    );
  }

  Future<void> _delete(ManageLocationsCubit cubit, LocationArea item) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'delete_location',
      descriptionKey: 'are_you_sure',
      confirmLabelKey: 'delete',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    if (result == AppConfirmResult.confirmed) {
      await cubit.delete(item);
    }
  }

  List<LocationArea> _placeholderLocations() {
    return List.generate(
      6,
      (i) => LocationArea(
        id: 'placeholder-$i',
        nameAr: 'loading_location'.tr(),
        nameEn: 'loading_location'.tr(),
        imageUrl: '',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  bool _isAreaComplete(LocationArea area) {
    return area.nameAr.trim().isNotEmpty &&
        area.nameEn.trim().isNotEmpty &&
        area.imageUrl.trim().isNotEmpty;
  }
}
