import 'package:flutter/foundation.dart';
import 'package:real_state/core/constants/user_role.dart';

/// Simple in-memory auth repository used for routing guards and
/// feature-level auth checks during early development.
class AuthRepository extends ChangeNotifier {
  bool _loggedIn = false;
  UserRole? _role;

  bool get isLoggedIn => _loggedIn;
  UserRole? get role => _role;

  Future<void> logIn() async {
    _loggedIn = true;
    notifyListeners();
  }

  Future<void> logOut() async {
    _loggedIn = false;
    _role = null;
    notifyListeners();
  }

  void updateRole(UserRole? role) {
    _role = role;
    notifyListeners();
  }
}
