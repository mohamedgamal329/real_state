import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_users_cubit.dart';
import 'package:provider/provider.dart';

class CreateCompanyUserBottomSheet extends StatefulWidget {
  const CreateCompanyUserBottomSheet({super.key});

  @override
  State<CreateCompanyUserBottomSheet> createState() =>
      _CreateCompanyUserBottomSheetState();
}

class _CreateCompanyUserBottomSheetState
    extends State<CreateCompanyUserBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  UserRole _role = UserRole.collector;
  bool _isSubmitting = false;
  bool _isFormValid = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _jobTitleCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _refreshValidity() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _isFormValid) {
      setState(() => _isFormValid = valid);
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      final cubit = context.read<ManageUsersCubit>();
      await LoadingDialog.show(
        context,
        cubit.create(
          email: _emailCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          jobTitle: _jobTitleCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          role: _role,
        ),
      );
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSubmit = _isFormValid && !_isSubmitting;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'add_user'.tr(),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: _refreshValidity,
              child: Column(
                children: [
                  AppTextField(
                    label: 'name'.tr(),
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final trimmed = v?.trim() ?? '';
                      if (trimmed.isEmpty) return 'name_required'.tr();
                      if (!Validators.isValidName(trimmed)) {
                        return 'name_too_short'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'email'.tr(),
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.isEmail(v) ? null : 'valid_email_required'.tr(),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'job_title'.tr(),
                    controller: _jobTitleCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.isNotEmpty(v) ? null : 'job_title_required'.tr(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    decoration: InputDecoration(labelText: 'role'.tr()),
                    initialValue: _role,
                    items: [
                      DropdownMenuItem(
                        value: UserRole.collector,
                        child: Text('collector'.tr()),
                      ),
                      DropdownMenuItem(
                        value: UserRole.broker,
                        child: Text('broker'.tr()),
                      ),
                      DropdownMenuItem(
                        value: UserRole.owner,
                        child: Text('owner'.tr()),
                      ),
                    ],
                    validator: (r) => Validators.isSelected(r) ? null : 'role_required'.tr(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _role = value);
                      _refreshValidity();
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'password'.tr(),
                    controller: _passwordCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'password_required'.tr();
                      if (!Validators.isStrongPassword(value)) {
                        return 'password_too_weak'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'confirm_password'.tr(),
                    controller: _confirmPasswordCtrl,
                    obscureText: true,
                    validator: (v) => Validators.passwordsMatch(
                              _passwordCtrl.text.trim(),
                              v?.trim(),
                            )
                        ? null
                        : 'passwords_not_match'.tr(),
                    onFieldSubmitted: (_) => _refreshValidity(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'add'.tr(),
              expand: false,
              isLoading: _isSubmitting,
              onPressed: canSubmit ? _submit : null,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
