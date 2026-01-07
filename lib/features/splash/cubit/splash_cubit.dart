import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/auth/auth_repository.dart';

enum SplashStatus { initial, unauthenticated, authenticated }

class SplashState {
  final SplashStatus status;
  const SplashState(this.status);
}

class SplashCubit extends Cubit<SplashState> {
  final AuthRepository auth;

  SplashCubit(this.auth) : super(const SplashState(SplashStatus.initial));

  Future<void> checkAuth() async {
    // check auth state and emit appropriate status
    if (auth.isLoggedIn) {
      emit(const SplashState(SplashStatus.authenticated));
    } else {
      emit(const SplashState(SplashStatus.unauthenticated));
    }
  }
}
