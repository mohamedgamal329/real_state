import '../../../../core/constants/user_role.dart';
import '../repositories/user_management_repository.dart';

class CreateUserUseCase {
  final UserManagementRepository _repo;
  CreateUserUseCase(this._repo);

  Future<void> call({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? jobTitle,
    String? phone,
  }) {
    return _repo.createUser(
      email: email,
      password: password,
      name: name,
      role: role,
      jobTitle: jobTitle,
      phone: phone,
    );
  }
}
