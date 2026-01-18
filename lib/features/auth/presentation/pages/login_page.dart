import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/auth/auth_repository.dart' as core_auth;
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/language_switcher.dart';
import 'package:real_state/core/handle_errors/failure_message_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:real_state/features/auth/presentation/cubit/auth_state.dart';
import 'package:real_state/features/auth/presentation/widgets/login_form.dart';
import 'package:real_state/features/auth/presentation/widgets/login_header.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final coreAuth = context.read<core_auth.AuthRepository>();
    final authDomain = RepositoryProvider.of<AuthRepositoryDomain>(context);

    return BlocProvider(
      create: (_) => AuthCubit(authDomain),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.authenticated) {
            coreAuth.logIn();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) GoRouter.of(context).go('/main');
            });
          }

          if (state.status == AuthStatus.failure && state.failure != null) {
            final message = mapFailureToMessage(state.failure!);
            AppSnackbar.show(context, message, type: AppSnackbarType.error);
          }
        },
        child: Scaffold(
          appBar: CustomAppBar(
            title: 'login'.tr(),
            actions: [LanguageSwitcher()],
          ),
          body: BaseGradientPage(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom * 0.1,
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 1, end: 0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 24 * value),
                          child: Opacity(
                            opacity: 1 - (value * 0.6),
                            child: child,
                          ),
                        );
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          key: const ValueKey('login_card'),
                          elevation: 2,
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 26,
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const LoginHeader(),
                                  const SizedBox(height: 18),
                                  const LoginForm(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
