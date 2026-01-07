import '../../../../core/failure/failure.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final Failure? failure;

  const AuthState._({required this.status, this.user, this.failure});

  const AuthState.initial() : this._(status: AuthStatus.initial);
  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.authenticated(UserEntity user)
    : this._(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);
  const AuthState.failure(Failure f)
    : this._(status: AuthStatus.failure, failure: f);
}
