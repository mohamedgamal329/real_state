import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/domain/services/notification_messaging_service.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/entities/notifications_page.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart'
    show PageResult;
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

class _FakeNotificationsRepo implements NotificationsRepository {
  _FakeNotificationsRepo({
    required this.pages,
    this.fetchDelay = Duration.zero,
  });

  final List<NotificationsPage> pages;
  final Duration fetchDelay;
  bool throwOnFetch = false;
  int fetchCount = 0;
  int markReadCount = 0;
  final List<String> marked = [];

  @override
  Future<NotificationsPage> fetchPage({
    required String userId,
    startAfter,
    int limit = 10,
  }) async {
    fetchCount++;
    if (throwOnFetch) throw Exception('fail');
    if (fetchDelay > Duration.zero) {
      await Future<void>.delayed(fetchDelay);
    }
    return pages.isNotEmpty
        ? pages.removeAt(0)
        : NotificationsPage(
            items: const [],
            lastDocument: null,
            hasMore: false,
          );
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    markReadCount++;
    marked.add(notificationId);
  }

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

  @override
  Future<void> sendPropertyAdded({
    required Property property,
    required String brief,
  }) async {}
}

class _FakeAuthRepo implements AuthRepositoryDomain {
  _FakeAuthRepo(this._initialUser);

  final UserEntity? _initialUser;
  late final StreamController<UserEntity?> _controller =
      StreamController<UserEntity?>.broadcast(
        onListen: () {
          if (_initialUser != null) {
            _controller.add(_initialUser);
          }
        },
      );

  void setUser(UserEntity? user) => _controller.add(user);

  @override
  UserEntity? get currentUser => _initialUser;

  @override
  Stream<UserEntity?> get userChanges => _controller.stream;

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> signInWithEmail(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) => throw UnimplementedError();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class _StubNotificationMessagingService
    implements NotificationMessagingService {
  _StubNotificationMessagingService();

  final StreamController<AppNotification> _fg =
      StreamController<AppNotification>.broadcast();
  final StreamController<AppNotification> _tap =
      StreamController<AppNotification>.broadcast();

  @override
  Stream<AppNotification> get foregroundNotifications => _fg.stream;

  @override
  Stream<AppNotification> get notificationTaps => _tap.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> attachUser(String? userId) async {}

  @override
  Future<void> detachUser() async {}

  @override
  Future<AppNotification?> initialMessage() async => null;

  void emitForeground(AppNotification notification) => _fg.add(notification);

  void emitTap(AppNotification notification) => _tap.add(notification);

  void dispose() {
    _fg.close();
    _tap.close();
  }
}

class _FakePropertiesRepo extends PropertiesRepositoryImpl {
  _FakePropertiesRepo(this.map) : super(FakeFirebaseFirestore());
  final Map<String, Property?> map;

  @override
  Future<Map<String, Property?>> fetchByIds(List<String> ids) async {
    final result = <String, Property?>{};
    for (final id in ids) {
      result[id] = map[id];
    }
    return result;
  }
}

class _FakeLocationAreasRepository implements LocationAreasRepository {
  _FakeLocationAreasRepository(this.names);
  final Map<String, LocationArea> names;

  @override
  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids) async {
    final res = <String, LocationArea>{};
    for (final id in ids) {
      if (names.containsKey(id)) res[id] = names[id]!;
    }
    return res;
  }

  @override
  Future<Map<String, LocationArea>> fetchAll() async => Map.of(names);
}

class _FakeAcceptUseCase extends AcceptAccessRequestUseCase {
  _FakeAcceptUseCase() : super(_FakeAccessRequestsRepo());
  bool shouldThrow = false;
  AccessRequest? result;

  @override
  Future<AccessRequest> call({
    required String requestId,
    required String userId,
    required UserRole? role,
  }) async {
    if (shouldThrow) throw Exception('fail');
    return result ??
        AccessRequest(
          id: requestId,
          propertyId: 'p1',
          requesterId: 'r1',
          type: AccessRequestType.phone,
          status: AccessRequestStatus.accepted,
          createdAt: DateTime.now(),
          ownerId: userId,
        );
  }
}

class _FakeRejectUseCase extends RejectAccessRequestUseCase {
  _FakeRejectUseCase() : super(_FakeAccessRequestsRepo());
  bool shouldThrow = false;
  AccessRequest? result;

  @override
  Future<AccessRequest> call({
    required String requestId,
    required String userId,
    required UserRole? role,
  }) async {
    if (shouldThrow) throw Exception('fail');
    return result ??
        AccessRequest(
          id: requestId,
          propertyId: 'p1',
          requesterId: 'r1',
          type: AccessRequestType.phone,
          status: AccessRequestStatus.rejected,
          createdAt: DateTime.now(),
          ownerId: userId,
        );
  }
}

class _FakeAccessRequestsRepo implements AccessRequestsRepository {
  _FakeAccessRequestsRepo();

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
    return AccessRequest(
      id: requestId,
      propertyId: 'p1',
      requesterId: 'r1',
      type: AccessRequestType.phone,
      status: status,
      createdAt: DateTime.now(),
      decidedBy: decidedBy,
    );
  }

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) => throw UnimplementedError();

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    PageToken? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async => PageResult(items: const [], lastDocument: null, hasMore: false);

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) => const Stream.empty();
}

class FakeFirebaseFirestore implements FirebaseFirestore {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseMessaging implements FirebaseMessaging {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuth implements fb_auth.FirebaseAuth {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppNotification _notification({
  required String id,
  AccessRequestStatus? status,
}) => AppNotification(
  id: id,
  type: AppNotificationType.accessRequest,
  title: 'n$id',
  body: '',
  createdAt: DateTime.now(),
  isRead: false,
  propertyId: 'p$id',
  requestId: 'r$id',
  requestType: AccessRequestType.phone,
  requestStatus: status ?? AccessRequestStatus.pending,
  targetUserId: 'u1',
);

void main() {
  final user = UserEntity(id: 'u1', role: UserRole.owner);
  late _FakeAuthRepo auth;
  late _FakeNotificationsRepo repo;
  late NotificationsBloc bloc;
  late _FakeAcceptUseCase acceptUseCase;
  late _FakeRejectUseCase rejectUseCase;

  NotificationsBloc _buildBloc({
    required List<NotificationsPage> pages,
    Map<String, Property?> props = const {},
    Map<String, LocationArea> areaNames = const {},
  }) {
    repo = _FakeNotificationsRepo(pages: pages);
    auth = _FakeAuthRepo(user);
    acceptUseCase = _FakeAcceptUseCase();
    rejectUseCase = _FakeRejectUseCase();
    final b = NotificationsBloc(
      repo,
      auth,
      _StubNotificationMessagingService(),
      _FakePropertiesRepo(props),
      _FakeLocationAreasRepository(areaNames),
      acceptUseCase,
      rejectUseCase,
    );
    return b;
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  test('initial load success', () async {
    final items = [_notification(id: '1')];
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: items, lastDocument: null, hasMore: false),
      ],
    );
    final emitted = <NotificationsState>[];
    final sub = bloc.stream.listen(emitted.add);
    final states = await bloc.stream
        .take(2)
        .toList()
        .timeout(const Duration(seconds: 1));
    expect(states[0], isA<NotificationsLoading>());
    expect(states[1], isA<NotificationsLoaded>());
    expect((states[1] as NotificationsLoaded).items, items);
    await sub.cancel();
    await bloc.close();
  });

  test('refresh failure mapped after initial success', () async {
    final items = [_notification(id: '1')];
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: items, lastDocument: null, hasMore: false),
      ],
    );
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    repo.throwOnFetch = true;
    bloc.add(const NotificationsRefreshRequested());
    final failure =
        await bloc.stream
                .firstWhere((s) => s is NotificationsFailure)
                .timeout(const Duration(seconds: 1))
            as NotificationsFailure;
    expect(failure.message, mapErrorMessage(Exception('fail')));
    await bloc.close();
  });

  test('refresh from loaded emits loaded', () async {
    final items = [_notification(id: '1')];
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: items, lastDocument: null, hasMore: false),
        NotificationsPage(
          items: [_notification(id: '2')],
          lastDocument: null,
          hasMore: false,
        ),
      ],
    );
    final emitted = <NotificationsState>[];
    final sub = bloc.stream.listen(emitted.add);
    await bloc.stream.firstWhere((s) => s is NotificationsLoaded);
    bloc.add(const NotificationsRefreshRequested());
    final refreshed = await bloc.stream
        .firstWhere((s) => s is NotificationsLoaded)
        .timeout(const Duration(seconds: 1));
    expect(refreshed, isA<NotificationsLoaded>());
    await sub.cancel();
    await bloc.close();
  });

  test('load more success appends items', () async {
    final first = [_notification(id: '1')];
    final second = [_notification(id: '2')];
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: first, lastDocument: null, hasMore: true),
        NotificationsPage(items: second, lastDocument: null, hasMore: false),
      ],
      props: {'p1': _fakeProperty('p1'), 'p2': _fakeProperty('p2')},
    );
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    final initialFetchCount = repo.fetchCount;
    bloc.add(const NotificationsLoadMoreRequested());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final state = bloc.state;
    expect(state, isA<NotificationsLoaded>());
    final loaded = state as NotificationsLoaded;
    expect(loaded.items.length, 2);
    expect(loaded.hasMore, false);
    expect(repo.fetchCount, initialFetchCount + 1);
    await bloc.close();
  });

  test('load more ignored when hasMore false', () async {
    final items = [_notification(id: '1')];
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: items, lastDocument: null, hasMore: false),
      ],
    );
    final emitted = <NotificationsState>[];
    final sub = bloc.stream.listen(emitted.add);
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    emitted.clear();
    bloc.add(const NotificationsLoadMoreRequested());
    await pump();
    expect(emitted, isEmpty);
    await sub.cancel();
    await bloc.close();
  });

  test('load more ignored while already loading', () async {
    final first = [_notification(id: '1')];
    final repoWithDelay = _FakeNotificationsRepo(
      pages: [
        NotificationsPage(items: first, lastDocument: null, hasMore: true),
        NotificationsPage(
          items: [_notification(id: '2')],
          lastDocument: null,
          hasMore: false,
        ),
      ],
      fetchDelay: const Duration(milliseconds: 100),
    );
    final authRepo = _FakeAuthRepo(user);
    bloc = NotificationsBloc(
      repoWithDelay,
      authRepo,
      _StubNotificationMessagingService(),
      _FakePropertiesRepo({'p1': _fakeProperty('p1')}),
      _FakeLocationAreasRepository(const {}),
      _FakeAcceptUseCase(),
      _FakeRejectUseCase(),
    );
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    final emitted = <NotificationsState>[];
    final sub = bloc.stream.listen(emitted.add);
    bloc.add(const NotificationsLoadMoreRequested());
    bloc.add(const NotificationsLoadMoreRequested());
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(emitted.whereType<NotificationsActionInProgress>().length, 1);
    expect(emitted.whereType<NotificationsLoaded>().length, 1);
    expect(repoWithDelay.fetchCount, 2); // initial + one loadMore
    await sub.cancel();
    await bloc.close();
  });

  test('mark read wraps previous loaded', () async {
    final notif = _notification(id: '1');
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: [notif], lastDocument: null, hasMore: false),
      ],
    );
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    bloc.add(NotificationsMarkReadRequested('1'));
    final states = await bloc.stream
        .take(3)
        .toList()
        .timeout(const Duration(seconds: 1));
    expect(states[0], isA<NotificationsActionInProgress>());
    expect(states[1], isA<NotificationsActionSuccess>());
    expect(states[2], isA<NotificationsLoaded>());
    final loaded = states.last as NotificationsLoaded;
    expect(loaded.items.first.isRead, true);
    await bloc.close();
  });

  test('accept failure emits mapped message and keeps data', () async {
    final notif = _notification(id: '1');
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: [notif], lastDocument: null, hasMore: false),
      ],
    );
    acceptUseCase.shouldThrow = true;
    final emitted = <NotificationsState>[];
    final sub = bloc.stream.listen(emitted.add);
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    emitted.clear();
    bloc.add(NotificationsAcceptRequested('1', 'r1'));
    await pump();
    expect(emitted.first, isA<NotificationsActionInProgress>());
    final failure = emitted.last as NotificationsActionFailure;
    expect(failure.message, mapErrorMessage(Exception('fail')));
    await sub.cancel();
    await bloc.close();
  });

  test('reject failure emits mapped message and keeps data', () async {
    final notif = _notification(id: '1');
    bloc = _buildBloc(
      pages: [
        NotificationsPage(items: [notif], lastDocument: null, hasMore: false),
      ],
    );
    rejectUseCase.shouldThrow = true;
    final emitted = <NotificationsState>[];
    final sub = bloc.stream.listen(emitted.add);
    final loadedFuture = bloc.stream.firstWhere(
      (s) => s is NotificationsLoaded,
    );
    await loadedFuture;
    emitted.clear();
    bloc.add(NotificationsRejectRequested('1', 'r1'));
    await pump();
    expect(emitted.first, isA<NotificationsActionInProgress>());
    final failure = emitted.last as NotificationsActionFailure;
    expect(failure.message, mapErrorMessage(Exception('fail')));
    await sub.cancel();
    await bloc.close();
  });
}

Property _fakeProperty(String id) => Property(
  id: id,
  title: 't$id',
  description: '',
  purpose: PropertyPurpose.sale,
  createdBy: 'u1',
  ownerScope: PropertyOwnerScope.company,
  locationUrl: '',
  imageUrls: const [],
  isImagesHidden: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  status: PropertyStatus.active,
  isDeleted: false,
);
