import 'package:flutter/foundation.dart';
import 'package:real_state/core/auth/current_user_accessor.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/user_role.dart';
import '../../../../core/handle_errors/error_mapper.dart';
import '../../../notifications/data/services/fcm_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository_domain.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepositoryDomain, CurrentUserAccessor {
  final AuthRemoteDataSource remote;
  final FcmService? _fcmService;

  AuthRepositoryImpl(this.remote, {FcmService? fcmService})
    : _fcmService = fcmService;

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    final user = await remote.signInWithEmail(email, password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', user.id);
    await prefs.setString('user_role', roleToString(user.role));
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    await prefs.setString('user_name', user.name ?? '');
    return user;
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final user = await remote.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', user.id);
    await prefs.setString('user_role', roleToString(user.role));
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    await prefs.setString('user_name', user.name ?? '');
    return user;
  }

  @override
  Future<void> signOut() async {
    try {
      await _fcmService?.detachUser();
    } catch (e, st) {
      debugPrint(
        'FCM detach failed during signOut: ${mapExceptionToFailure(e, st)}',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_role');
    await prefs.remove('user_email');
    await prefs.remove('user_password');
    await prefs.remove('user_name');
    await remote.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return remote.sendPasswordResetEmail(email);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Stream<UserEntity?> get userChanges => remote.authStateChanges();

  @override
  UserRole? get currentRole => remote.currentUser?.role;

  @override
  String? get currentUserId => remote.currentUser?.id;

  @override
  UserEntity? get currentUser {
    final u = remote.currentUser;
    if (u == null) return null;
    return UserEntity(id: u.id, email: u.email, name: u.name, role: u.role);
  }
}
