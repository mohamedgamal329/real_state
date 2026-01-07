import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_collections.dart';
import '../../../../core/constants/user_role.dart';
import '../../../../core/errors/localized_exception.dart';
import '../../domain/entities/managed_user.dart';
import '../dtos/managed_user_dto.dart';

class UsersRepository {
  final FirebaseFirestore _firestore;
  final String _collection;

  UsersRepository(this._firestore, {String? collection})
    : _collection = collection ?? AppCollections.users.path;

  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    Query<Map<String, dynamic>> q = _firestore.collection(_collection);
    if (role != null) q = q.where('role', isEqualTo: roleToString(role));
    final snap = await q.get();
    return snap.docs.map(ManagedUserDto.fromDoc).toList();
  }

  Future<ManagedUser> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    return ManagedUserDto.fromDoc(doc);
  }

  Future<void> createUser({
    required String id,
    required String email,
    required UserRole role,
    String? name,
    String? phone,
  }) async {
    if (role == UserRole.owner) {
      throw const LocalizedException('error_owner_cannot_create');
    }
    final timestamp = FieldValue.serverTimestamp();
    final map = {
      'email': email,
      'role': roleToString(role),
      'name': name,
      'phone': phone,
      'active': true,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    };
    await _firestore.collection(_collection).doc(id).set(map);
  }

  Future<void> updateUser({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  }) async {
    final map = <String, Object?>{};
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (role != null) map['role'] = roleToString(role);
    if (map.isNotEmpty) {
      map['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).doc(id).update(map);
    }
  }

  Future<void> deleteUser(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }
}
