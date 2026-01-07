import 'package:real_state/core/constants/user_role.dart';

class UserEntity {
  final String id;
  final String? email;
  final String? name;
  final UserRole role;

  const UserEntity({
    required this.id,
    this.email,
    this.name,
    required this.role,
  });
}
