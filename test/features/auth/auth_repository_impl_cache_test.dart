import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:real_state/features/auth/data/models/user_model.dart';
import 'package:real_state/features/auth/data/repositories/auth_repository_impl.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  test(
    'AuthRepositoryImpl.currentUser/currentRole follow authStateChanges (not currentUser fallback)',
    () async {
      final remote = _MockAuthRemoteDataSource();
      final controller = StreamController<UserModel?>.broadcast(sync: true);
      addTearDown(controller.close);

      when(
        () => remote.authStateChanges(),
      ).thenAnswer((_) => controller.stream);
      when(() => remote.currentUser).thenReturn(
        const UserModel(
          id: 'u1',
          email: 'u@x',
          name: 'Stale',
          role: UserRole.owner,
        ),
      );

      final repo = AuthRepositoryImpl(remote);
      addTearDown(repo.disposeForTests);

      const actual = UserModel(
        id: 'u1',
        email: 'u@x',
        name: 'Actual',
        role: UserRole.broker,
      );
      controller.add(actual);
      await Future<void>.delayed(Duration.zero);

      expect(repo.currentUser?.role, UserRole.broker);
      expect(repo.currentRole, UserRole.broker);
      expect(repo.currentUserId, 'u1');
    },
  );

  test(
    'AuthRepositoryImpl.userChanges replays cached user to late subscribers',
    () async {
      final remote = _MockAuthRemoteDataSource();
      final controller = StreamController<UserModel?>.broadcast(sync: true);
      addTearDown(controller.close);

      when(
        () => remote.authStateChanges(),
      ).thenAnswer((_) => controller.stream);
      when(() => remote.currentUser).thenReturn(null);

      final repo = AuthRepositoryImpl(remote);
      addTearDown(repo.disposeForTests);

      const actual = UserModel(
        id: 'u1',
        email: 'u@x',
        name: 'Actual',
        role: UserRole.broker,
      );
      controller.add(actual);
      await Future<void>.delayed(Duration.zero);

      // Subscribe after the auth event already happened: should still get the user.
      final lateValue = await repo.userChanges.first;
      expect(lateValue?.id, 'u1');
      expect(lateValue?.role, UserRole.broker);
    },
  );
}
