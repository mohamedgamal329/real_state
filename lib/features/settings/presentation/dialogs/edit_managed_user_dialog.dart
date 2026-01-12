import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_users_cubit.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

class EditManagedUserDialog extends StatefulWidget {
  const EditManagedUserDialog({
    super.key,
    required this.user,
    required this.canAssignOwner,
  });

  final ManagedUser user;
  final bool canAssignOwner;

  @override
  State<EditManagedUserDialog> createState() => _EditManagedUserDialogState();
}

class _EditManagedUserDialogState extends State<EditManagedUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phoneCtrl =
      TextEditingController(text: widget.user.phone);
  late UserRole _role = widget.user.role;
  late UserRole _previousRole = _role;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<bool> _confirmOwnerAssignment() async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'transfer_ownership',
      descriptionKey: 'ownership_transfer_warning',
      confirmLabelKey: 'confirm',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    return result == AppConfirmResult.confirmed;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<ManageUsersCubit>();
    await LoadingDialog.show(
      context,
      cubit.update(
        id: widget.user.id,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        role: _role,
      ),
    );
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('edit_role'.tr(args: [_roleLabel(_role)])),
      content: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom * 0.4, top: 8),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'name'.tr(),
                controller: _nameCtrl,
                validator: (v) =>
                    Validators.isValidName(v) ? null : 'name_too_short'.tr(),
              ),
              const SizedBox(height: 8),
              AppTextField(
                label: 'phone'.tr(),
                controller: _phoneCtrl,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: InputDecoration(labelText: 'role'.tr()),
                items: [
                  DropdownMenuItem(
                    value: UserRole.collector,
                    child: Text('collector'.tr()),
                  ),
                  DropdownMenuItem(
                    value: UserRole.broker,
                    child: Text('broker'.tr()),
                  ),
                  if (widget.canAssignOwner)
                    DropdownMenuItem(
                      value: UserRole.owner,
                      child: Text('owner'.tr()),
                    ),
                ],
                validator: (role) =>
                    Validators.isSelected(role) ? null : 'role_required'.tr(),
                onChanged: (role) async {
                  if (role == null) return;
                  if (role == UserRole.owner && widget.canAssignOwner) {
                    final confirmed = await _confirmOwnerAssignment();
                    if (!confirmed) {
                      setState(() => _role = _previousRole);
                      return;
                    }
                  }
                  setState(() {
                    _previousRole = _role;
                    _role = role;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('cancel'.tr()),
        ),
        PrimaryButton(
          label: 'save'.tr(),
          expand: false,
          onPressed: _save,
        ),
      ],
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.collector:
        return 'collectors'.tr();
      case UserRole.broker:
        return 'brokers'.tr();
      case UserRole.owner:
        return 'owner'.tr();
    }
  }
}
