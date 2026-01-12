import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/domain/entities/broker.dart';
import 'package:real_state/features/brokers/domain/repositories/brokers_repository.dart';
import 'package:real_state/features/brokers/domain/usecases/get_brokers_usecase.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_bloc.dart';
import 'package:real_state/features/properties/presentation/bloc/property_mutations_bloc.dart';
import 'package:real_state/features/settings/presentation/pages/manage_users_page.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

class FakeUserManagementRepository implements UserManagementRepository {
  final List<ManagedUser> collectors = [];
  final List<ManagedUser> brokers = [];

  @override
  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    if (role == UserRole.collector) return List.of(collectors);
    if (role == UserRole.broker) return List.of(brokers);
    return [...collectors, ...brokers];
  }

  @override
  Future<ManagedUser?> fetchUser(String id) async {
    for (final user in collectors) {
      if (user.id == id) return user;
    }
    for (final user in brokers) {
      if (user.id == id) return user;
    }
    return null;
  }

  @override
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phone,
    String? jobTitle,
  }) async {
    final user = ManagedUser(
      id: email,
      email: email,
      name: name,
      role: role,
      jobTitle: jobTitle,
    );
    if (role == UserRole.collector) {
      collectors.add(user);
    } else {
      brokers.add(user);
    }
  }

  @override
  Future<void> updateUser({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  }) async {}

  @override
  Future<void> disableUser(String id) async {
    collectors.removeWhere((u) => u.id == id);
    brokers.removeWhere((u) => u.id == id);
  }
}

class FakeAuthRepository implements AuthRepositoryDomain {
  static const _owner = UserEntity(
    id: 'owner',
    email: 'owner@example.com',
    name: 'Owner',
    role: UserRole.owner,
  );
  final Stream<UserEntity?> _userChanges;

  FakeAuthRepository()
      : _userChanges = Stream<UserEntity?>.value(_owner).asBroadcastStream();

  @override
  Future<UserEntity> signInWithEmail(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Stream<UserEntity?> get userChanges => _userChanges;

  @override
  UserEntity? get currentUser => _owner;
}

class FakeBrokersRepository implements BrokersRepository {
  @override
  Future<List<Broker>> fetchBrokers() async => const [];
}

void main() {
  testWidgets('ManageUsersPage shows tabs and users', (tester) async {
    final repo = FakeUserManagementRepository();
    repo.collectors.addAll([
      ManagedUser(
        id: 'e1',
        email: 'e1@x.com',
        role: UserRole.collector,
        name: 'Emp1',
      ),
    ]);
    repo.brokers.addAll([
      ManagedUser(
        id: 'b1',
        email: 'b1@x.com',
        role: UserRole.broker,
        name: 'Bro1',
      ),
    ]);

    final propertyMutationsBloc = PropertyMutationsBloc();
    addTearDown(propertyMutationsBloc.close);
    final brokersListBloc = BrokersListBloc(
      GetBrokersUseCase(FakeBrokersRepository()),
      FakeAuthRepository(),
      propertyMutationsBloc,
    );
    addTearDown(brokersListBloc.close);

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<UserManagementRepository>.value(
          value: repo,
          child: BlocProvider<BrokersListBloc>.value(
            value: brokersListBloc,
            child: const ManageUsersPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Emp1'), findsOneWidget);
    expect(find.text('Bro1'), findsNothing);
    await tester.tap(find.text('Brokers'));
    await tester.pumpAndSettle();
    expect(find.text('Bro1'), findsOneWidget);
  });
}
