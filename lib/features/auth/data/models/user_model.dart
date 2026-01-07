import '../../../../core/constants/user_role.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.email,
    super.name,
    required super.role,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      email: map['email'] as String?,
      name: map['name'] as String?,
      role: roleFromString(map['role'] as String?),
    );
  }
}
