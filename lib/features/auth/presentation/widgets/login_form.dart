import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/auth/presentation/cubit/auth_cubit.dart';

class _Account {
  final String email;
  final String password;

  _Account({required this.email, required this.password});
}

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

  final List<_Account> _accounts = [
    _Account(email: 'mahmedgamal329@gmail.com', password: 'MahmedGamal12'),
    _Account(email: 'ahmedelwan1@gmail.com', password: '0552860601Aa'),
    _Account(email: 'ahmedelwan2@gmail.com', password: '0552860601Aa'),
  ];

  _Account get currentAcc {
    return _accounts[1];
  }

  @override
  void initState() {
    if (kDebugMode) {
      _emailCtrl.text = currentAcc.email;
      _passCtrl.text = currentAcc.password;
    }
    super.initState();
  }

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

            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: const AppSvgIcon(AppSVG.mail),
            ),
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
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12.0),
              child: const AppSvgIcon(AppSVG.lock),
            ),
            suffixIcon: IconButton(
              icon: AppSvgIcon(
                _obscure ? AppSVG.visibilityOff : AppSVG.visibility,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) =>
                Validators.isMinLength(v, 6) ? null : 'password_required'.tr(),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'sign_in'.tr(),
            iconWidget: AppSvgIcon(AppSVG.login),

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
