import '../entities/user_entity.dart';
import '../repositories/auth_repository_domain.dart';

class SignInUseCase {
  final AuthRepositoryDomain repository;

  SignInUseCase(this.repository);

  Future<UserEntity> call(String email, String password) async {
    return repository.signInWithEmail(email, password);
  }
}
