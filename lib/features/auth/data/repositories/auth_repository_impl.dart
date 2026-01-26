import 'dart:async';

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

  final StreamController<UserEntity?> _userChangesController =
      StreamController<UserEntity?>.broadcast(sync: true);
  StreamSubscription<UserEntity?>? _authStateSub;
  bool _hasAuthState = false;
  UserEntity? _cachedUser;

  AuthRepositoryImpl(this.remote, {FcmService? fcmService})
    : _fcmService = fcmService {
    _authStateSub = remote.authStateChanges().listen(
      (user) {
        _hasAuthState = true;
        _cachedUser = user == null
            ? null
            : UserEntity(
                id: user.id,
                email: user.email,
                name: user.name,
                role: user.role,
              );
        _userChangesController.add(_cachedUser);
      },
      onError: _userChangesController.addError,
    );
  }

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
  Stream<UserEntity?> get userChanges => Stream<UserEntity?>.multi((controller) {
    if (_hasAuthState) {
      controller.add(_cachedUser);
    }
    final sub = _userChangesController.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    controller.onCancel = sub.cancel;
  });

  @override
  UserRole? get currentRole => _cachedUser?.role;

  @override
  String? get currentUserId => _cachedUser?.id;

  @override
  UserEntity? get currentUser => _cachedUser;

  @visibleForTesting
  void disposeForTests() {
    _authStateSub?.cancel();
    _authStateSub = null;
    _userChangesController.close();
  }
}
