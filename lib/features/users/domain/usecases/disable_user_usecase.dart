import '../repositories/user_management_repository.dart';

class DisableUserUseCase {
  final UserManagementRepository _repo;
  DisableUserUseCase(this._repo);

  Future<void> call(String id) {
    return _repo.disableUser(id);
  }
}
