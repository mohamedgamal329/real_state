import 'dart:async';

import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/domain/entities/notifications_page.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart'
    show PageResult;
import 'package:real_state/features/users/data/repositories/users_repository.dart';

import 'fake_firebase.dart';

class FakePropertiesRepository extends PropertiesRepositoryImpl {
  FakePropertiesRepository({Map<String, Property?>? seeds})
    : _storage = Map.of(seeds ?? const {}),
      super(FakeFirebaseFirestore());

  final Map<String, Property?> _storage;

  void seed(String id, Property property) => _storage[id] = property;

  @override
  Future<Property?> getById(String id) async => _storage[id];

  @override
  Future<Map<String, Property?>> fetchByIds(List<String> ids) async {
    final result = <String, Property?>{};
    for (final id in ids) {
      result[id] = _storage[id];
    }
    return result;
  }
}

class FakeAccessRequestsRepository implements AccessRequestsRepository {
  FakeAccessRequestsRepository();

  final Map<String, AccessRequest> _requests = {};
  final Map<String, StreamController<AccessRequest?>> _controllers = {};
  String? lastCreatedRequestId;

  static String _key(
    String propertyId,
    String requesterId,
    AccessRequestType type,
  ) => '$propertyId|$requesterId|${type.name}';

  StreamController<AccessRequest?> _controllerForKey(String key) {
    return _controllers.putIfAbsent(
      key,
      () => StreamController<AccessRequest?>.broadcast(sync: true),
    );
  }

  AccessRequest? _latestForKey(String key) {
    final matches = _requests.values
        .where((r) => _key(r.propertyId, r.requesterId, r.type) == key)
        .toList();
    if (matches.isEmpty) return null;
    return matches.last;
  }

  void _emitForRequest(AccessRequest request) {
    final key = _key(request.propertyId, request.requesterId, request.type);
    if (_controllers.containsKey(key)) {
      _controllers[key]!.add(request);
    }
  }

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    final id = 'req_${_requests.length + 1}';
    final now = DateTime.now();
    final request = AccessRequest(
      id: id,
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
      message: message,
      status: AccessRequestStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      ownerId: targetUserId,
    );
    _requests[id] = request;
    _emitForRequest(request);
    lastCreatedRequestId = id;
    return request;
  }

  @override
  Future<AccessRequest?> fetchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    final key = _key(propertyId, requesterId, type);
    return _latestForKey(key);
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    final key = _key(propertyId, requesterId, type);
    final controller = _controllerForKey(key);
    controller.onListen = () {
      final stored = _latestForKey(key);
      if (stored != null) controller.add(stored);
    };
    return controller.stream;
  }

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    PageToken? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async {
    return PageResult(items: const [], lastDocument: null, hasMore: false);
  }

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async {
    final existing = _requests[requestId];
    if (existing == null) throw StateError('Missing request $requestId');
    final updated = AccessRequest(
      id: existing.id,
      propertyId: existing.propertyId,
      requesterId: existing.requesterId,
      type: existing.type,
      message: existing.message,
      status: status,
      createdAt: existing.createdAt,
      expiresAt: existing.expiresAt,
      decidedAt: DateTime.now(),
      decidedBy: decidedBy,
      ownerId: existing.ownerId,
    );
    _requests[requestId] = updated;
    _emitForRequest(updated);
    return updated;
  }

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    for (final request in _requests.values) {
      if (request.propertyId == propertyId &&
          request.requesterId == requesterId &&
          request.type == type &&
          request.status == AccessRequestStatus.accepted) {
        return request;
      }
    }
    return null;
  }

  @override
  Future<AccessRequest?> fetchById(String id) async => _requests[id];
}

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({List<NotificationsPage>? initialPages})
    : _pages = List.of(initialPages ?? []);

  final List<NotificationsPage> _pages;

  void seedPages(List<NotificationsPage> pages) {
    _pages
      ..clear()
      ..addAll(pages);
  }

  @override
  Future<NotificationsPage> fetchPage({
    required String userId,
    Object? startAfter,
    int limit = 10,
  }) async {
    if (_pages.isEmpty) {
      return NotificationsPage(
        items: const [],
        lastDocument: null,
        hasMore: false,
      );
    }
    return _pages.removeAt(0);
  }

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> sendPropertyAdded({
    required Property property,
    required String brief,
  }) async {}

  @override
  Future<void> sendAccessRequest({
    required String requestId,
    required String propertyId,
    required String targetUserId,
    required String requesterId,
    required AccessRequestType type,
    String? requesterName,
    String? message,
  }) async {}

  @override
  Future<void> sendAccessRequestDecision({
    required AccessRequest request,
    required bool accepted,
  }) async {}

  @override
  Future<void> sendGeneral({
    required String title,
    required String body,
    List<String>? userIds,
  }) async {}
}

class FakeUsersRepository implements UsersRepository {
  FakeUsersRepository({Iterable<ManagedUser>? seeds})
    : _store = {
        for (final user in seeds ?? const <ManagedUser>[]) user.id: user,
      };

  final Map<String, ManagedUser> _store;

  void seed(ManagedUser user) => _store[user.id] = user;

  @override
  Future<List<ManagedUser>> fetchUsers({UserRole? role}) async {
    final values = _store.values;
    if (role == null) return values.toList();
    return values.where((user) => user.role == role).toList();
  }

  @override
  Future<ManagedUser> getById(String id) async {
    final user = _store[id];
    if (user == null) {
      throw StateError('User $id not found');
    }
    return user;
  }

  @override
  Future<void> createUser({
    required String id,
    required String email,
    required UserRole role,
    String? name,
    String? phone,
  }) async {
    _store[id] = ManagedUser(
      id: id,
      email: email,
      role: role,
      name: name,
      phone: phone,
    );
  }

  @override
  Future<void> updateUser({
    required String id,
    String? name,
    String? phone,
    UserRole? role,
  }) async {
    final existing = _store[id];
    if (existing == null) return;
    _store[id] = ManagedUser(
      id: existing.id,
      role: role ?? existing.role,
      name: name ?? existing.name,
      email: existing.email,
      phone: phone ?? existing.phone,
      active: existing.active,
    );
  }

  @override
  Future<void> deleteUser(String id) async => _store.remove(id);
}
