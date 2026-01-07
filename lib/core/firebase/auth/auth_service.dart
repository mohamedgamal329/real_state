abstract class AuthService {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signOut();
}
