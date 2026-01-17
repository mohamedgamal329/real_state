import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/access_requests/domain/resolve_access_request_target_usecase.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/users_lookup_repository.dart';

class _FakeUsersLookupRepository implements UsersLookupRepository {
  _FakeUsersLookupRepository(this.usersById);

  final Map<String, ManagedUser> usersById;

  @override
  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    return usersById.values
        .where((u) => role == null || u.role == role)
        .toList();
  }

  @override
  Future<ManagedUser> getById(String id) async {
    final user = usersById[id];
    if (user == null) {
      throw StateError('User not found');
    }
    return user;
  }
}

void main() {
  test('broker-scoped properties target the broker', () async {
    final repo = _FakeUsersLookupRepository({
      'broker1': const ManagedUser(id: 'broker1', role: UserRole.broker),
      'owner1': const ManagedUser(id: 'owner1', role: UserRole.owner),
    });
    final useCase = ResolveAccessRequestTargetUseCase(repo);
    final property = Property(
      id: 'p1',
      title: 't',
      purpose: PropertyPurpose.sale,
      createdBy: 'broker1',
      ownerScope: PropertyOwnerScope.broker,
      brokerId: 'broker1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final target = await useCase.resolveTarget(property);
    expect(target, 'broker1');
  });

  test('company properties target the active owner', () async {
    final repo = _FakeUsersLookupRepository({
      'ownerInactive': const ManagedUser(
        id: 'ownerInactive',
        role: UserRole.owner,
        active: false,
      ),
      'ownerActive': const ManagedUser(
        id: 'ownerActive',
        role: UserRole.owner,
        active: true,
      ),
      'broker1': const ManagedUser(id: 'broker1', role: UserRole.broker),
    });
    final useCase = ResolveAccessRequestTargetUseCase(repo);
    final property = Property(
      id: 'p2',
      title: 't',
      purpose: PropertyPurpose.sale,
      createdBy: 'collector1',
      ownerScope: PropertyOwnerScope.company,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final target = await useCase.resolveTarget(property);
    expect(target, 'ownerActive');
  });
}
