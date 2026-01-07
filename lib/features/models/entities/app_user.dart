import 'package:meta/meta.dart';
import 'package:real_state/core/constants/user_role.dart';

@immutable
class AppUser {
  final String id;
  final String? name;
  final String? email;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.id,
    this.name,
    this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  String toString() => 'AppUser(id: $id, email: $email, role: $role)';
}
