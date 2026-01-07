import '../../../../core/constants/user_role.dart';
import '../entities/user_entity.dart';

abstract class AuthRepositoryDomain {
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });
  Future<void> signOut();
  Stream<UserEntity?> get userChanges;
  UserEntity? get currentUser;
}
