import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/brokers/domain/entities/broker.dart';
import 'package:real_state/features/brokers/domain/repositories/brokers_repository.dart';
import 'package:real_state/features/brokers/domain/usecases/get_brokers_usecase.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_bloc.dart';
import 'package:real_state/features/properties/presentation/side_effects/property_mutations_bloc.dart';
import 'package:real_state/features/settings/presentation/pages/manage_users_page.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

import '../fake_auth_repo/fake_auth_repo.dart';
import '../../helpers/pump_test_app.dart';

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
  }) async {
    final user = ManagedUser(id: email, email: email, name: name, role: role);
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

class FakeBrokersRepository implements BrokersRepository {
  @override
  Future<List<Broker>> fetchBrokers() async => const [];
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

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
      FakeAuthRepo(
        const UserEntity(
          id: 'owner',
          email: 'owner@example.com',
          name: 'Owner',
          role: UserRole.owner,
        ),
      ),
      propertyMutationsBloc,
    );
    addTearDown(brokersListBloc.close);

    await pumpTestApp(
      tester,
      const ManageUsersPage(),
      additionalProviders: [
        RepositoryProvider<UserManagementRepository>.value(value: repo),
        BlocProvider<BrokersListBloc>.value(value: brokersListBloc),
      ],
    );

    final skeletonFinder = find.byType(AppSkeletonList);
    for (var i = 0; i < 40 && tester.any(skeletonFinder); i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    final collectorRow = byKeyStr('manage_user_e1');
    await pumpUntilFound(tester, collectorRow);
    expect(collectorRow, findsOneWidget);
    expect(byKeyStr('manage_user_b1'), findsNothing);

    await tester.tap(byKeyStr('manage_users_tab_brokers'));
    final brokerRow = byKeyStr('manage_user_b1');
    await pumpUntilFound(tester, brokerRow);
    expect(brokerRow, findsOneWidget);
  });
}
