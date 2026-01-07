import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/auth/auth_repository.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/features/splash/cubit/splash_cubit.dart';
import 'package:real_state/features/splash/presentation/widgets/splash_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final SplashCubit _splashCubit;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthRepository>();
    _splashCubit = SplashCubit(auth);

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _splashCubit.checkAuth();
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _splashCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _splashCubit,
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state.status == SplashStatus.authenticated) {
            context.go('/main');
          } else if (state.status == SplashStatus.unauthenticated) {
            context.go('/login');
          }
        },
        child: Scaffold(
          body: BaseGradientPage(
            child: Center(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  return Opacity(
                    opacity: _ctrl.value,
                    child: Transform.scale(scale: _scale.value, child: child),
                  );
                },
                child: const AppLogo(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
