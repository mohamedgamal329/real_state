import '../../../../core/constants/user_role.dart';
import '../repositories/user_management_repository.dart';

class UpdateUserUseCase {
  final UserManagementRepository _repo;
  UpdateUserUseCase(this._repo);

  Future<void> call({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  }) {
    return _repo.updateUser(id: id, name: name, phone: phone, role: role);
  }
}
