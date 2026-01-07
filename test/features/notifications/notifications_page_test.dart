import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/access_requests/data/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/presentation/pages/notifications_page.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_auth_repo/fake_auth_repo.dart';

class _FakeAccessRepo implements AccessRequestsRepository {
  List<AccessRequest> _items = [];

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async {
    return PageResult(items: _items, lastDocument: null, hasMore: false);
  }

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async {
    final idx = _items.indexWhere((i) => i.id == requestId);
    if (idx >= 0) {
      final old = _items[idx];
      final updated = AccessRequest(
        id: old.id,
        propertyId: old.propertyId,
        requesterId: old.requesterId,
        type: old.type,
        message: old.message,
        status: status,
        createdAt: old.createdAt,
        expiresAt: old.expiresAt,
        decidedAt: DateTime.now(),
        decidedBy: decidedBy,
      );
      _items[idx] = updated;
      return updated;
    }
    throw Exception('not found');
  }

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    for (final item in _items) {
      if (item.propertyId == propertyId &&
          item.requesterId == requesterId &&
          item.type == type &&
          item.status == AccessRequestStatus.accepted) {
        return item;
      }
    }
    return null;
  }

  @override
  Future<AccessRequest?> fetchById(String id) async {
    try {
      return _items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    return const Stream.empty();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('owner sees pending requests and can accept', (tester) async {
    final fakeRepo = _FakeAccessRepo();
    final now = DateTime.now();
    fakeRepo._items = [
      AccessRequest(
        id: 'r1',
        propertyId: 'p1',
        requesterId: 'u2',
        type: AccessRequestType.images,
        message: 'please',
        status: AccessRequestStatus.pending,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    ];

    final fakeAuth = FakeAuthRepo(
      const UserEntity(id: 'owner1', email: 'o@x', role: UserRole.owner),
    );

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: MultiProvider(
              providers: [
                Provider<AccessRequestsRepository>.value(value: fakeRepo),
                Provider<AuthRepositoryDomain>.value(value: fakeAuth),
              ],
              child: const NotificationsPage(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // pending request shown
    expect(find.text('Requester: u2'), findsOneWidget);
    expect(find.text('Message: please'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);

    // tap accept
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    // after accept, the status badge should update to ACCEPTED
    expect(find.text('ACCEPTED'), findsOneWidget);
  });
}
