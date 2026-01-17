import 'package:real_state/core/constants/user_role.dart';

/// Minimal abstraction to expose the current authenticated user's role
/// without coupling helpers to specific auth implementations or Flutter.
abstract class CurrentUserAccessor {
  UserRole? get currentRole;
  String? get currentUserId;
}
