import '../entities/managed_user.dart';

import '../../../../core/constants/user_role.dart';

abstract class UserManagementRepository {
  Future<List<ManagedUser>> fetchUsers({UserRole? role});
  Future<ManagedUser?> fetchUser(String id);
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? jobTitle,
  });
  Future<void> updateUser({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  });
  Future<void> disableUser(String id);
}
