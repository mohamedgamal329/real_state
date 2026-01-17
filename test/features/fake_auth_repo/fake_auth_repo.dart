import 'dart:async';

import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';

class FakeAuthRepo implements AuthRepositoryDomain {
  final UserEntity? _user;

  FakeAuthRepo(this._user);

  @override
  Future<UserEntity> signInWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  UserEntity? get currentUser => _user;

  @override
  Stream<UserEntity?> get userChanges {
    final ctrl = StreamController<UserEntity?>.broadcast(sync: true);
    ctrl.onListen = () => ctrl.add(_user);
    return ctrl.stream;
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }
}
