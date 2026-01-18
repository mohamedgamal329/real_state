import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/animations/slide_fade_in.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/widgets/location_area_card.dart';
import 'package:real_state/core/widgets/location_area_form_dialog.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_locations_cubit.dart';

class ManageLocationsPage extends StatelessWidget {
  const ManageLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubitFactory = context.read<ManageLocationsCubit Function()>();
    return BlocProvider(
      create: (context) => cubitFactory()..initialize(),
      child: const ManageLocationsView(),
    );
  }
}

class ManageLocationsView extends StatelessWidget {
  const ManageLocationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageLocationsCubit, ManageLocationsState>(
      listener: (context, state) {
        if (state is ManageLocationsFailure) {
          AppSnackbar.show(context, state.message, type: AppSnackbarType.error);
        } else if (state is ManageLocationsPartialFailure) {
          AppSnackbar.show(context, state.message, type: AppSnackbarType.error);
        } else if (state is ManageLocationsAccessDenied) {
          AppSnackbar.show(context, state.message, type: AppSnackbarType.error);
        }
      },
      builder: (context, state) {
        if (state is ManageLocationsAccessDenied) {
          return Scaffold(
            appBar: CustomAppBar(title: 'manage_locations'.tr()),
            body: AppErrorView(
              message: state.message,
              onRetry: () => context.read<ManageLocationsCubit>().initialize(),
            ),
          );
        }

        if (state is ManageLocationsFailure &&
            state is! ManageLocationsDataState) {
          return Scaffold(
            appBar: CustomAppBar(title: 'manage_locations'.tr()),
            body: AppErrorView(
              message: state.message,
              onRetry: () => context.read<ManageLocationsCubit>().initialize(),
            ),
          );
        }

        final dataState = state is ManageLocationsDataState ? state : null;
        final showSkeleton =
            state is ManageLocationsCheckingAccess ||
            state is ManageLocationsLoadInProgress;

        if (showSkeleton) {
          return _ManageLocationsSkeleton(
            localeCode: context.locale.toString(),
            placeholder: _placeholderLocations().first,
          );
        }

        final items = dataState?.items ?? [];
        final canInteract =
            dataState != null && state is! ManageLocationsActionInProgress;

        return Scaffold(
          appBar: CustomAppBar(title: 'manage_locations'.tr()),
          body: items.isEmpty
              ? _ManageLocationsEmpty(
                  onCreate: () => _createLocation(
                    context,
                    context.read<ManageLocationsCubit>(),
                  ),
                )
              : _ManageLocationsList(
                  items: items,
                  canInteract: canInteract,
                  localeCode: context.locale.toString(),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () =>
                _createLocation(context, context.read<ManageLocationsCubit>()),
            child: const AppSvgIcon(AppSVG.add),
          ),
        );
      },
    );
  }
}

class _ManageLocationsSkeleton extends StatelessWidget {
  final String localeCode;
  final LocationArea placeholder;

  const _ManageLocationsSkeleton({
    required this.localeCode,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'manage_locations'.tr()),
      body: AppSkeletonList(
        itemBuilder: (_, __) =>
            LocationAreaCard(area: placeholder, localeCode: localeCode),
      ),
    );
  }
}

class _ManageLocationsEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _ManageLocationsEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      description: 'no_locations_description'.tr(),
      action: onCreate,
    );
  }
}

class _ManageLocationsList extends StatelessWidget {
  final List<LocationArea> items;
  final bool canInteract;
  final String localeCode;

  const _ManageLocationsList({
    required this.items,
    required this.canInteract,
    required this.localeCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (c, i) {
        final it = items[i];
        return SlideFadeIn(
          delay: Duration(milliseconds: 40 * i),
          child: LocationAreaCard(
            area: it,
            localeCode: localeCode,
            onEdit: canInteract && _isAreaComplete(it)
                ? () => _editLocation(
                    context,
                    context.read<ManageLocationsCubit>(),
                    it,
                  )
                : null,
            onDelete: canInteract && _isAreaComplete(it)
                ? () => _deleteLocation(
                    context,
                    context.read<ManageLocationsCubit>(),
                    it,
                  )
                : null,
          ),
        );
      },
    );
  }
}

Future<void> _createLocation(
  BuildContext context,
  ManageLocationsCubit cubit,
) async {
  // Unfocus before dialog
  FocusScope.of(context).unfocus();

  final res = await LocationAreaFormDialog.show(context);
  if (res == null || res.imageFile == null) return;

  // Unfocus again before loading overlay (though LoadingDialog.show will also do it)
  FocusScope.of(context).unfocus();

  await LoadingDialog.show(
    context,
    cubit.create(
      nameAr: res.nameAr,
      nameEn: res.nameEn,
      imageFile: res.imageFile!,
    ),
  );
}

Future<void> _editLocation(
  BuildContext context,
  ManageLocationsCubit cubit,
  LocationArea item,
) async {
  // Unfocus before dialog
  FocusScope.of(context).unfocus();

  final res = await LocationAreaFormDialog.show(context, initial: item);
  if (res == null) return;

  // Unfocus again before loading overlay
  FocusScope.of(context).unfocus();

  await LoadingDialog.show(
    context,
    cubit.update(
      item,
      nameAr: res.nameAr,
      nameEn: res.nameEn,
      imageFile: res.imageFile,
    ),
  );
}

Future<void> _deleteLocation(
  BuildContext context,
  ManageLocationsCubit cubit,
  LocationArea item,
) async {
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
