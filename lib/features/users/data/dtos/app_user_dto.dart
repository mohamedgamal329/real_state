import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/entities/app_user.dart';
import '../../../../core/constants/user_role.dart';

class AppUserDto {
  AppUserDto._();

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final roleStr = (data['role'] as String?) ?? 'owner';
    final role = roleFromString(roleStr);

    return AppUser(
      id: doc.id,
      name: data['name'] as String?,
      email: data['email'] as String?,
      role: role,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, Object?> toMap(AppUser user) {
    return {
      'name': user.name,
      'email': user.email,
      'role': roleToString(user.role),
      'createdAt': Timestamp.fromDate(user.createdAt),
      'updatedAt': Timestamp.fromDate(user.updatedAt),
    };
  }
}
