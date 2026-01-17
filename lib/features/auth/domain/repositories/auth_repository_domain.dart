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
  Future<void> sendPasswordResetEmail(String email);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> signOut();
  Stream<UserEntity?> get userChanges;
  UserEntity? get currentUser;
}
