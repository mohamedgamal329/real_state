import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/user_role.dart';
import '../../domain/entities/managed_user.dart';

class ManagedUserDto {
  ManagedUserDto._();

  static ManagedUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ManagedUser(
      id: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      jobTitle: data['jobTitle'] as String?,
      role: roleFromString(data['role'] as String?),
      phone: data['phone'] as String?,
      active: (data['active'] as bool?) ?? true,
    );
  }

  static Map<String, Object?> toMap(ManagedUser user) => {
    'name': user.name,
    'email': user.email,
    'jobTitle': user.jobTitle,
    'role': roleToString(user.role),
    'phone': user.phone,
    'active': user.active,
  };
}
