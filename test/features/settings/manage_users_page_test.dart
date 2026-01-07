import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/settings/presentation/pages/manage_users_page.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

class FakeUsersRepository extends UsersRepository {
  FakeUsersRepository() : super(FirebaseFirestore.instance);
  List<ManagedUser> employees = [];
  List<ManagedUser> brokers = [];
  @override
  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    if (role == UserRole.collector) return employees;
    if (role == UserRole.broker) return brokers;
    return [];
  }

  @override
  Future<void> createUser({
    required String id,
    required String email,
    required UserRole role,
    String? name,
    String? phone,
  }) async {
    if (role == UserRole.collector) {
      employees.add(ManagedUser(id: id, email: email, role: role, name: name));
    } else {
      brokers.add(ManagedUser(id: id, email: email, role: role, name: name));
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
  Future<void> deleteUser(String id) async {
    employees.removeWhere((e) => e.id == id);
    brokers.removeWhere((b) => b.id == id);
  }
}

void main() {
  testWidgets('ManageUsersPage shows tabs and users', (tester) async {
    final repo = FakeUsersRepository();
    repo.employees = [
      ManagedUser(
        id: 'e1',
        email: 'e1@x.com',
        role: UserRole.collector,
        name: 'Emp1',
      ),
    ];
    repo.brokers = [
      ManagedUser(
        id: 'b1',
        email: 'b1@x.com',
        role: UserRole.broker,
        name: 'Bro1',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<UsersRepository>.value(
          value: repo,
          child: const ManageUsersPage(),
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
