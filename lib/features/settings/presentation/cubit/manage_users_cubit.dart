import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';

import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/usecases/create_user_usecase.dart';
import 'package:real_state/features/users/domain/usecases/disable_user_usecase.dart';
import 'package:real_state/features/users/domain/usecases/update_user_usecase.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';
import 'package:real_state/core/constants/user_role.dart';

part 'manage_users_state.dart';

class ManageUsersCubit extends Cubit<ManageUsersState> {
  final UserManagementRepository _repo;
  final UpdateUserUseCase _updateUser;
  final DisableUserUseCase _disableUser;
  final CreateUserUseCase _createUser;
  final bool isOwner;

  ManageUsersCubit(this._repo, {required this.isOwner})
    : _updateUser = UpdateUserUseCase(_repo),
      _disableUser = DisableUserUseCase(_repo),
      _createUser = CreateUserUseCase(_repo),
      super(const ManageUsersInitial());

  bool _hasPermission() {
    if (isOwner) return true;
    emit(ManageUsersFailure('access_denied_owner'.tr()));
    return false;
  }

  Future<void> load() async {
    if (!_hasPermission()) return;
    emit(const ManageUsersLoadInProgress());
    try {
      final collectors = await _repo.fetchUsers(role: UserRole.collector);
      final brokers = await _repo.fetchUsers(role: UserRole.broker);
      emit(ManageUsersLoadSuccess(collectors: collectors, brokers: brokers));
    } catch (e) {
      emit(ManageUsersFailure(mapErrorMessage(e)));
    }
  }

  Future<void> update({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  }) async {
    if (!_hasPermission()) return;
    final current = _dataState();
    emit(
      ManageUsersActionInProgress(
        collectors: current.collectors,
        brokers: current.brokers,
      ),
    );
    try {
      await _updateUser(id: id, name: name, phone: phone, role: role);
      await load();
    } catch (e) {
      emit(
        ManageUsersPartialFailure(
          collectors: current.collectors,
          brokers: current.brokers,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  Future<void> delete(String id) async {
    if (!_hasPermission()) return;
    final current = _dataState();
    emit(
      ManageUsersActionInProgress(
        collectors: current.collectors,
        brokers: current.brokers,
      ),
    );
    try {
      await _disableUser(id);
      await load();
    } catch (e) {
      emit(
        ManageUsersPartialFailure(
          collectors: current.collectors,
          brokers: current.brokers,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  Future<void> create({
    required String email,
    required UserRole role,
    required String name,
    required String jobTitle,
    required String password,
  }) async {
    if (!_hasPermission()) return;
    final current = _dataState();
    emit(
      ManageUsersActionInProgress(
        collectors: current.collectors,
        brokers: current.brokers,
      ),
    );
    try {
      await _createUser(
        email: email,
        password: password,
        name: name,
        role: role,
        jobTitle: jobTitle,
      );
      await load();
    } catch (e) {
      emit(
        ManageUsersPartialFailure(
          collectors: current.collectors,
          brokers: current.brokers,
          message: mapErrorMessage(e),
        ),
      );
    }
  }

  _ManageUsersData _dataState() {
    if (state is ManageUsersLoadSuccess) {
      final s = state as ManageUsersLoadSuccess;
      return _ManageUsersData(s.collectors, s.brokers);
    }
    return const _ManageUsersData([], []);
  }
}

class _ManageUsersData {
  const _ManageUsersData(this.collectors, this.brokers);
  final List<ManagedUser> collectors;
  final List<ManagedUser> brokers;
}
