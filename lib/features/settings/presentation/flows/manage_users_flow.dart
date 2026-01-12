import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/features/settings/presentation/bottom_sheets/create_company_user_bottom_sheet.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_users_cubit.dart';
import 'package:real_state/features/settings/presentation/dialogs/edit_managed_user_dialog.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

class ManageUsersFlow {
  const ManageUsersFlow();

  Future<void> openCreateUserSheet(BuildContext context) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateCompanyUserBottomSheet(),
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
    await showDialog<bool>(
      context: context,
      builder: (_) => EditManagedUserDialog(
        user: user,
        canAssignOwner: canAssignOwner,
      ),
    );
  }

  Future<void> confirmAndDeleteUser(BuildContext context, ManagedUser user) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'delete_user',
      descriptionKey: 'are_you_sure',
      confirmLabelKey: 'disable',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    if (result != AppConfirmResult.confirmed) return;
    await context.read<ManageUsersCubit>().delete(user.id);
    AppSnackbar.show(context, 'user_disabled'.tr());
  }
}
