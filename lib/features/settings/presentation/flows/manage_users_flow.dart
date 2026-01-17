import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/utils/async_action_guard.dart';
import 'package:real_state/features/settings/presentation/bottom_sheets/create_company_user_bottom_sheet.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_users_cubit.dart';
import 'package:real_state/features/settings/presentation/dialogs/edit_managed_user_dialog.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

class ManageUsersFlow {
  ManageUsersFlow() : _deleteGuard = AsyncActionGuard();

  final AsyncActionGuard _deleteGuard;

  Future<void> openCreateUserSheet(BuildContext context) async {
    final cubit = context.read<ManageUsersCubit>();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const CreateCompanyUserBottomSheet(),
      ),
    );
    if (created == true) {
      AppSnackbar.show(context, 'user_created'.tr());
    }
  }

  Future<void> openEditUserSheetOrDialog(
    BuildContext context,
    ManagedUser user, {
    required bool canAssignOwner,
  }) async {
    final cubit = context.read<ManageUsersCubit>();
    await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: EditManagedUserDialog(
          user: user,
          canAssignOwner: canAssignOwner,
        ),
      ),
    );
  }

  Future<void> confirmAndDeleteUser(
    BuildContext context,
    ManagedUser user,
  ) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'delete_user',
      descriptionKey: 'are_you_sure',
      confirmLabelKey: 'disable',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    if (result != AppConfirmResult.confirmed) return;
    await _deleteGuard.run(() async {
      await context.read<ManageUsersCubit>().delete(user.id);
      AppSnackbar.show(context, 'user_disabled'.tr());
    });
  }
}
