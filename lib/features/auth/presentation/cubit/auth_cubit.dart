import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/failure/failure.dart';
import '../../../../core/failure/unknown_failure.dart';
// Use direct repository calls; use failure_message_mapper in UI layer for display
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository_domain.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepositoryDomain _repo;
  StreamSubscription<UserEntity?>? _sub;

  AuthCubit(this._repo) : super(const AuthState.initial()) {
    _sub = _repo.userChanges.listen(_onUserChanged);
  }

  void _onUserChanged(UserEntity? u) {
    if (u == null) {
      emit(const AuthState.unauthenticated());
    } else {
      emit(AuthState.authenticated(u));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthState.loading());
    try {
      final user = await _repo.signInWithEmail(email, password);
      emit(AuthState.authenticated(user));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AuthCubit signIn error: $e');
        debugPrintStack(stackTrace: st);
      }
      if (e is Failure) {
        emit(AuthState.failure(e));
      } else {
        emit(AuthState.failure(const UnknownFailure()));
      }
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
