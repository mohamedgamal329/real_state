import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/settings/domain/usecases/load_theme_mode_usecase.dart';
import 'package:real_state/features/settings/domain/usecases/update_theme_mode_usecase.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final AuthRepositoryDomain _auth;
  final UserManagementRepository _userRepo;
  final LoadThemeModeUseCase _loadThemeMode;
  final UpdateThemeModeUseCase _updateThemeMode;
  StreamSubscription? _sub;

  SettingsCubit(
    this._auth,
    this._userRepo,
    this._loadThemeMode,
    this._updateThemeMode,
  ) : super(const SettingsHydrating(themeMode: ThemeMode.system)) {
    _sub = _auth.userChanges.listen((user) {
      emit(
        _rebuildState(
          userRole: user?.role,
          userEmail: user?.email,
          userId: user?.id,
          userName: user?.name ?? user?.email,
        ),
      );
      if (user?.id != null) {
        unawaited(_loadProfile(user!.id));
      }
    });
    _loadTheme();
  }

  Future<void> _loadProfile(String id) async {
    try {
      final ManagedUser? profile = await _userRepo.fetchUser(id);
      if (profile != null) {
        emit(_rebuildState(userName: profile.name));
      }
    } catch (_) {}
  }

  Future<void> _loadTheme() async {
    final mode = await _loadThemeMode();
    emit(_rebuildState(themeMode: mode));
  }

  Future<void> changeTheme(ThemeMode mode) async {
    emit(_rebuildState(themeMode: mode));
    await _updateThemeMode(mode);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> updateProfile({
    required String id,
    required String? name,
  }) async {
    emit(
      SettingsProfileUpdating(
        themeMode: state.themeMode,
        userId: state.userId,
        userEmail: state.userEmail,
        userRole: state.userRole,
        userName: state.userName,
      ),
    );
    try {
      await _userRepo.updateUser(id: id, name: name);
      emit(
        SettingsReady(
          themeMode: state.themeMode,
          userId: state.userId,
          userEmail: state.userEmail,
          userRole: state.userRole,
          userName: name,
        ),
      );
    } catch (e) {
      emit(
        SettingsFailure(
          themeMode: state.themeMode,
          userId: state.userId,
          userEmail: state.userEmail,
          userRole: state.userRole,
          userName: state.userName,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }

  SettingsState _rebuildState({
    String? userId,
    String? userEmail,
    UserRole? userRole,
    String? userName,
    ThemeMode? themeMode,
  }) {
    final nextUserId = userId ?? state.userId;
    final nextEmail = userEmail ?? state.userEmail;
    final nextRole = userRole ?? state.userRole;
    final nextName = userName ?? state.userName;
    final nextTheme = themeMode ?? state.themeMode;

    if (state is SettingsFailure) {
      final failure = state as SettingsFailure;
      return SettingsFailure(
        message: failure.message,
        themeMode: nextTheme,
        userId: nextUserId,
        userEmail: nextEmail,
        userRole: nextRole,
        userName: nextName,
      );
    }

    if (state is SettingsProfileUpdating) {
      return SettingsProfileUpdating(
        themeMode: nextTheme,
        userId: nextUserId,
        userEmail: nextEmail,
        userRole: nextRole,
        userName: nextName,
      );
    }

    final hasUser = nextUserId != null;
    if (hasUser || state is SettingsReady) {
      return SettingsReady(
        themeMode: nextTheme,
        userId: nextUserId,
        userEmail: nextEmail,
        userRole: nextRole,
        userName: nextName,
      );
    }
    return SettingsHydrating(
      themeMode: nextTheme,
      userId: nextUserId,
      userEmail: nextEmail,
      userRole: nextRole,
      userName: nextName,
    );
  }
}
