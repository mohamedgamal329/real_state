import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:real_state/core/constants/app_collections.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/failure/firestore_failure.dart';

import '../../../../core/failure/auth_failure.dart';
import '../../../../core/failure/unknown_failure.dart';
import '../../../../core/handle_errors/error_mapper.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSource(this._auth, this._firestore);

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const UnknownFailure();

      final profile = await _fetchProfile(user.uid);
      return UserModel(
        id: user.uid,
        email: user.email,
        name: profile.$1,
        role: profile.$2,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('signInWithEmail failed: $e\n$st');
      if (e is AuthFailure) rethrow;
      final failure = mapExceptionToFailure(e, st);
      throw failure;
    }
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (role == UserRole.owner) {
      throw const AuthFailure(error: 'invalid_role');
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw const UnknownFailure();

      final timestamp = FieldValue.serverTimestamp();
      await _firestore.collection(AppCollections.users.path).doc(user.uid).set({
        'email': email.trim(),
        'name': name,
        'role': roleToString(role),
        'active': true,
        'createdAt': timestamp,
        'updatedAt': timestamp,
      });
      return UserModel(id: user.uid, email: user.email, name: name, role: role);
    } catch (e, st) {
      if (kDebugMode) debugPrint('signUp failed: $e\n$st');
      if (e is AuthFailure) rethrow;
      final failure = mapExceptionToFailure(e, st);
      throw failure;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('sendPasswordResetEmail failed: $e\n$st');
      }
      if (e is AuthFailure) rethrow;
      final failure = mapExceptionToFailure(e, st);
      throw failure;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw const AuthFailure(error: 'not_signed_in');
      }
      final credential = fb.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('changePassword failed: $e\n$st');
      }
      if (e is AuthFailure) rethrow;
      final failure = mapExceptionToFailure(e, st);
      throw failure;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((fb.User? u) async {
      if (u == null) return null;
      try {
        final profile = await _fetchProfile(u.uid);
        return UserModel(
          id: u.uid,
          email: u.email,
          name: profile.$1,
          role: profile.$2,
        );
      } on AuthFailure catch (e) {
        debugPrint('Auth stream failed to fetch profile: $e');
        await _auth.signOut();
        return null;
      } on FirestoreFailure catch (e) {
        debugPrint('Auth stream firestore failure: ${e.error}');
        await _auth.signOut();
        return null;
      } catch (e, st) {
        final failure = mapExceptionToFailure(e, st);
        debugPrint('Auth stream unexpected error: $failure');
        await _auth.signOut();
        return null;
      }
    });
  }

  UserModel? get currentUser {
    final u = _auth.currentUser;
    if (u == null) return null;
    return UserModel(
      id: u.uid,
      email: u.email,
      name: u.displayName,
      role: UserRole.owner, // Fallback; actual role resolved via profile stream
    );
  }

  Future<(String?, UserRole)> _fetchProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppCollections.users.path)
          .doc(uid)
          .get();
      if (!doc.exists) {
        throw const AuthFailure(error: 'profile_missing');
      }
      final map = doc.data() as Map<String, dynamic>;
      final active = map['active'] is bool ? map['active'] as bool : true;
      if (!active) throw const AuthFailure(error: 'inactive_user');
      final role = roleFromString(map['role'] as String?);
      final name = map['name'] as String?;
      return (name, role);
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        throw FirestoreFailure(error: e);
      }
      if (e is AuthFailure) rethrow;
      throw AuthFailure(error: e);
    }
  }
}
