import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_state/firebase_options.dart';

import '../../../../core/constants/user_role.dart';
import '../../../../core/errors/localized_exception.dart';
import '../../domain/entities/managed_user.dart';
import '../dtos/managed_user_dto.dart';

class UsersRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final String collection;

  UsersRemoteDataSource(this.firestore, this.auth, {required this.collection});

  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    Query<Map<String, dynamic>> q = firestore.collection(collection);
    if (role != null) q = q.where('role', isEqualTo: roleToString(role));
    final snap = await q.get();
    return snap.docs.map(ManagedUserDto.fromDoc).toList();
  }

  Future<ManagedUser?> fetchUser(String id) async {
    final doc = await firestore.collection(collection).doc(id).get();
    if (!doc.exists) return null;
    return ManagedUserDto.fromDoc(doc);
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? jobTitle,
  }) async {
    final ownerSession = await _ensureOwnerWithCredentials();
    final secondaryAuth = await _secondaryAuth();
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final trimmedJobTitle = jobTitle?.trim();
    final jobTitleValue = (trimmedJobTitle?.isNotEmpty == true) ? trimmedJobTitle : null;
    try {
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const LocalizedException('error_create_user_failed');
      }
      final timestamp = FieldValue.serverTimestamp();
      await firestore.collection(collection).doc(user.uid).set({
        'email': trimmedEmail,
        'name': trimmedName,
        'jobTitle': jobTitleValue,
        'role': roleToString(role),
        'phone': phone,
        'companyId': ownerSession.companyId,
        'permissions': const [],
        'active': true,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw const LocalizedException('error_email_already_in_use');
        case 'weak-password':
          throw const LocalizedException('password_too_weak');
        case 'invalid-email':
          throw const LocalizedException('valid_email_required');
      }
      rethrow;
    } finally {
      await secondaryAuth.signOut();
    }
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
    if (map.isEmpty) return;
    map['updatedAt'] = FieldValue.serverTimestamp();
    await firestore.collection(collection).doc(id).update(map);
  }

  Future<void> disableUser({required String id}) async {
    await _ensureOwnerWithCredentials();
    await firestore.collection(collection).doc(id).update({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns (email, password) for the current owner after verifying active role.
  Future<_OwnerSession> _ensureOwnerWithCredentials() async {
    final owner = auth.currentUser;
    if (owner == null) throw const LocalizedException('error_auth_required');

    final doc = await firestore.collection(collection).doc(owner.uid).get();
    final data = doc.data();
    final isOwner = (data?['role'] as String?)?.toLowerCase() == 'owner';
    final isActive = data?['active'] != false;
    if (!isOwner || !isActive)
      throw const LocalizedException('error_owner_access');

    final prefs = await SharedPreferences.getInstance();
    final ownerEmail = prefs.getString('user_email');
    final ownerPassword = prefs.getString('user_password');
    if (ownerEmail == null || ownerPassword == null) {
      throw const LocalizedException('error_owner_session');
    }
    final companyId = (data?['companyId'] as String?) ?? owner.uid;
    return _OwnerSession(ownerEmail, ownerPassword, companyId);
  }

  Future<FirebaseAuth> _secondaryAuth() async {
    try {
      final app = Firebase.app('secondary');
      return FirebaseAuth.instanceFor(app: app);
    } on FirebaseException catch (e) {
      if (e.code != 'no-app') rethrow;
    }
    final app = await Firebase.initializeApp(
      name: 'secondary',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirebaseAuth.instanceFor(app: app);
  }
}

class _OwnerSession {
  final String email;
  final String password;
  final String companyId;

  const _OwnerSession(this.email, this.password, this.companyId);
}
