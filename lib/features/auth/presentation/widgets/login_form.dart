import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/auth/presentation/cubit/auth_cubit.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            label: 'email'.tr(),
            hintText: 'email'.tr(),
            controller: _emailCtrl,
            textInputAction: TextInputAction.next,

            keyboardType: TextInputType.emailAddress,

            prefixIcon: const Icon(Icons.mail_outline),
            validator: (v) =>
                Validators.isEmail(v) ? null : 'valid_email_required'.tr(),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'password'.tr(),
            hintText: 'password'.tr(),
            controller: _passCtrl,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                Validators.isMinLength(v, 6) ? null : 'password_required'.tr(),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'sign_in'.tr(),
            onPressed: () async {
              if (_formKey.currentState?.validate() != true) return;
              await LoadingDialog.show(
                context,
                context.read<AuthCubit>().signIn(
                  _emailCtrl.text.trim(),
                  _passCtrl.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
