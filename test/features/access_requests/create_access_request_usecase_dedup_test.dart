import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/access_requests/domain/resolve_access_request_target_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/create_access_request_usecase.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart'
    show PageResult;
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/users_lookup_repository.dart';

class _FakeUsersLookupRepo implements UsersLookupRepository {
  _FakeUsersLookupRepo(this._ownerId);

  final String _ownerId;

  @override
  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    return [
      ManagedUser(
        id: _ownerId,
        email: 'o@x',
        role: UserRole.owner,
        active: true,
      ),
    ];
  }

  @override
  Future<ManagedUser> getById(String id) async {
    return ManagedUser(id: id, email: 'u@x', role: UserRole.owner, active: true);
  }
}

class _FakeAccessRequestsRepo implements AccessRequestsRepository {
  AccessRequest? latest;
  int createCalls = 0;

  @override
  Future<AccessRequest?> fetchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    return latest;
  }

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    createCalls++;
    return AccessRequest(
      id: 'new',
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
      status: AccessRequestStatus.pending,
      createdAt: DateTime.now(),
      ownerId: targetUserId,
      message: message,
    );
  }

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    return null;
  }

  @override
  Future<AccessRequest?> fetchById(String id) async => null;

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async {
    throw UnimplementedError();
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) => const Stream.empty();

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    PageToken? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) => throw UnimplementedError();
}

void main() {
  final property = Property(
    id: 'p1',
    purpose: PropertyPurpose.sale,
    createdBy: 'owner1',
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  test('does not create duplicate when latest is pending', () async {
    final repo = _FakeAccessRequestsRepo()
      ..latest = AccessRequest(
        id: 'existing',
        propertyId: 'p1',
        requesterId: 'broker1',
        type: AccessRequestType.phone,
        status: AccessRequestStatus.pending,
        createdAt: DateTime(2024),
        ownerId: 'owner1',
      );
    final useCase = CreateAccessRequestUseCase(
      repo,
      ResolveAccessRequestTargetUseCase(_FakeUsersLookupRepo('owner1')),
    );

    final result = await useCase(
      property: property,
      requesterId: 'broker1',
      type: AccessRequestType.phone,
    );

    expect(result.created, isFalse);
    expect(result.request.id, 'existing');
    expect(repo.createCalls, 0);
  });

  test('does not create duplicate when latest is accepted', () async {
    final repo = _FakeAccessRequestsRepo()
      ..latest = AccessRequest(
        id: 'existing',
        propertyId: 'p1',
        requesterId: 'broker1',
        type: AccessRequestType.phone,
        status: AccessRequestStatus.accepted,
        createdAt: DateTime(2024),
        ownerId: 'owner1',
      );
    final useCase = CreateAccessRequestUseCase(
      repo,
      ResolveAccessRequestTargetUseCase(_FakeUsersLookupRepo('owner1')),
    );

    final result = await useCase(
      property: property,
      requesterId: 'broker1',
      type: AccessRequestType.phone,
    );

    expect(result.created, isFalse);
    expect(result.request.id, 'existing');
    expect(repo.createCalls, 0);
  });

  test('allows retry when latest is rejected', () async {
    final repo = _FakeAccessRequestsRepo()
      ..latest = AccessRequest(
        id: 'existing',
        propertyId: 'p1',
        requesterId: 'broker1',
        type: AccessRequestType.phone,
        status: AccessRequestStatus.rejected,
        createdAt: DateTime(2024),
        ownerId: 'owner1',
      );
    final useCase = CreateAccessRequestUseCase(
      repo,
      ResolveAccessRequestTargetUseCase(_FakeUsersLookupRepo('owner1')),
    );

    final result = await useCase(
      property: property,
      requesterId: 'broker1',
      type: AccessRequestType.phone,
    );

    expect(result.created, isTrue);
    expect(result.request.id, 'new');
    expect(repo.createCalls, 1);
  });
}
