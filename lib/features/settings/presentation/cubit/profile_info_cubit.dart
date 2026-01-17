import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

class ProfileInfoState extends Equatable {
  final bool isLoading;
  final String? name;
  final String? email;
  final String? errorMessage;

  const ProfileInfoState({
    this.isLoading = false,
    this.name,
    this.email,
    this.errorMessage,
  });

  ProfileInfoState copyWith({
    bool? isLoading,
    String? name,
    String? email,
    String? errorMessage,
  }) {
    return ProfileInfoState(
      isLoading: isLoading ?? this.isLoading,
      name: name ?? this.name,
      email: email ?? this.email,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, name, email, errorMessage];
}

class ProfileInfoCubit extends Cubit<ProfileInfoState> {
  final AuthRepositoryDomain _auth;
  final UserManagementRepository _users;

  ProfileInfoCubit(this._auth, this._users) : super(const ProfileInfoState());

  Future<void> load() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      emit(const ProfileInfoState(isLoading: false));
      return;
    }
    emit(
      state.copyWith(
        isLoading: true,
        name: currentUser.name,
        email: currentUser.email,
        errorMessage: null,
      ),
    );
    try {
      final profile = await _users.fetchUser(currentUser.id);
      emit(_mergeProfile(profile, currentUser.name, currentUser.email));
    } catch (e, st) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: mapErrorMessage(e, stackTrace: st),
        ),
      );
    }
  }

  Future<void> sendPasswordReset() async {
    final email = state.email;
    if (email == null || email.trim().isEmpty) {
      throw StateError('missing_email');
    }
    await _auth.sendPasswordResetEmail(email.trim());
  }

  Future<void> changePasswordInApp({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _auth.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  ProfileInfoState _mergeProfile(
    ManagedUser? profile,
    String? name,
    String? email,
  ) {
    return ProfileInfoState(
      isLoading: false,
      name: profile?.name ?? name,
      email: profile?.email ?? email,
    );
  }
}
