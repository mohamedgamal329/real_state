import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/constants/app_spacing.dart';

/// Dialog for in-app password change with current, new, and confirm fields.
/// Returns a tuple of (currentPassword, newPassword) on success, null on cancel.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  static Future<({String currentPassword, String newPassword})?> show(
    BuildContext context,
  ) {
    return showDialog<({String currentPassword, String newPassword})>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ChangePasswordDialog(),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr();
    }
    if (value.length < 8 ||
        !value.contains(RegExp(r'[a-zA-Z]')) ||
        !value.contains(RegExp(r'[0-9]'))) {
      return 'password_too_weak'.tr();
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _newController.text) {
      return 'passwords_not_match'.tr();
    }
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    // Unfocus before popping to dismiss keyboard and avoid disposal crashes
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop((
      currentPassword: _currentController.text,
      newPassword: _newController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('change_password'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                label: 'current_password'.tr(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'password_required'.tr() : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _newController,
                obscureText: _obscureNew,
                label: 'new_password'.tr(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                label: 'confirm_password'.tr(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: _validateConfirm,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(onPressed: _submit, child: Text('save'.tr())),
      ],
    );
  }
}
