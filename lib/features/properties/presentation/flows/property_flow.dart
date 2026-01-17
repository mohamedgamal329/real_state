import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/utils/async_action_guard.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_event.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_state.dart';
import 'package:real_state/features/properties/presentation/dialogs/property_request_dialog.dart';

class PropertyFlow {
  PropertyFlow()
    : _mutationGuard = AsyncActionGuard(),
      _restoreGuard = AsyncActionGuard();

  final AsyncActionGuard _mutationGuard;
  final AsyncActionGuard _restoreGuard;
  StreamSubscription<PropertyDetailState>? _snackbarSub;

  void startSnackbars(BuildContext context) {
    _snackbarSub ??= context.read<PropertyDetailBloc>().stream.listen(
      (state) => _handleSnackbar(context, state),
    );
  }

  ValueListenable<bool> get mutationGuard => _mutationGuard;

  Future<void> openShareSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ListTile(
                leading: const AppSvgIcon(AppSVG.photo),
                title: Text('share_images_only'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () {
                  context.pop();
                  context.read<PropertyDetailBloc>().add(
                    PropertyShareImagesRequested(context),
                  );
                },
              ),
              ListTile(
                leading: const AppSvgIcon(AppSVG.pdf),
                title: Text('share_details_pdf'.tr()),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () {
                  context.pop();
                  context.read<PropertyDetailBloc>().add(
                    PropertySharePdfRequested(context),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> requestAccess(
    BuildContext context,
    String propertyId,
    AccessRequestType type,
  ) async {
    final loaded = _loadedFrom(context.read<PropertyDetailBloc>().state);
    final requestProperty = loaded?.property;
    final result = await PropertyRequestDialog.show(
      context,
      type,
      property: requestProperty,
    );
    if (result == null) return;
    await LoadingDialog.show(
      context,
      Future.sync(() {
        context.read<PropertyDetailBloc>().add(
          PropertyAccessRequested(
            propertyId: propertyId,
            type: type,
            message: result,
          ),
        );
      }),
    );
  }

  Future<void> archiveProperty(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'archive_property_title',
      descriptionKey: 'archive_property_confirm',
      confirmLabelKey: 'archive',
      cancelLabelKey: 'cancel',
    );
    if (result != AppConfirmResult.confirmed) return;
    await _mutationGuard.run(() async {
      context.read<PropertyDetailBloc>().add(const PropertyArchiveRequested());
    });
  }

  Future<void> deleteProperty(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'delete_property_title',
      descriptionKey: 'delete_property_confirm',
      confirmLabelKey: 'delete',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    if (result != AppConfirmResult.confirmed) return;
    await _mutationGuard.run(() async {
      context.read<PropertyDetailBloc>().add(const PropertyDeleteRequested());
      final state = context.read<PropertyDetailBloc>().state;
      final wasSuccess = state is PropertyDetailActionSuccess && !state.isError;
      if (wasSuccess) {
        context.pop();
      }
    });
  }

  Future<void> requestRestore(BuildContext context) async {
    await _restoreGuard.run(() async {
      context.read<PropertyDetailBloc>().add(const PropertyRestoreRequested());
    });
  }

  void dispose() {
    _mutationGuard.dispose();
    _restoreGuard.dispose();
    _snackbarSub?.cancel();
    _snackbarSub = null;
  }

  void _handleSnackbar(BuildContext context, PropertyDetailState state) {
    if (state is PropertyDetailActionSuccess && state.message != null) {
      final message = state.message!;
      final archiveMessage = 'property_archived_success'.tr();
      if (message == archiveMessage) {
        AppSnackbar.show(
          context,
          message,
          type: AppSnackbarType.warning,
          actionLabel: 'undo'.tr(),
          onAction: () => requestRestore(context),
        );
      } else {
        final type = state.isError
            ? AppSnackbarType.error
            : AppSnackbarType.success;
        AppSnackbar.show(context, message, type: type);
      }
      return;
    }
    if (state is PropertyDetailFailure) {
      AppSnackbar.show(context, state.message, type: AppSnackbarType.error);
    }
  }

  PropertyDetailLoaded? _loadedFrom(PropertyDetailState state) {
    if (state is PropertyDetailLoaded) return state;
    if (state is PropertyDetailActionSuccess) return state.data;
    if (state is PropertyDetailShareInProgress) return state.data;
    if (state is PropertyDetailShareSuccess) return state.data;
    if (state is PropertyDetailShareFailure) return state.data;
    return null;
  }
}
