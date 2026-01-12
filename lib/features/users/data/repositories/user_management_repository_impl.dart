import '../../../../core/constants/user_role.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/users_remote_datasource.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UsersRemoteDataSource _remote;

  UserManagementRepositoryImpl(this._remote);

  @override
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? jobTitle,
  }) async {
    return _remote.createUser(
      email: email,
      password: password,
      name: name,
      role: role,
      phone: phone,
      jobTitle: jobTitle,
    );
  }

  @override
  Future<List<ManagedUser>> fetchUsers({UserRole? role}) {
    return _remote.fetchUsers(role: role);
  }

  @override
  Future<ManagedUser?> fetchUser(String id) {
    return _remote.fetchUser(id);
  }

  @override
  Future<void> updateUser({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  }) {
    return _remote.updateUser(id: id, name: name, phone: phone, role: role);
  }

  @override
  Future<void> disableUser(String id) {
    return _remote.disableUser(id: id);
  }
}
