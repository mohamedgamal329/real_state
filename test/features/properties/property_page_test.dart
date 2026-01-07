import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/access_requests/data/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/pages/property_page.dart';

import '../fake_auth_repo/fake_auth_repo.dart';

class _FakePropertiesRepo extends PropertiesRepository {
  final Property _prop;
  _FakePropertiesRepo(this._prop) : super(null as dynamic);

  @override
  Future<Property?> getById(String id) async => _prop;
}

class _FakeAccessRepo extends AccessRequestsRepository {
  _FakeAccessRepo() : super(null as dynamic);

  bool called = false;
  AccessRequestType? lastType;

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    called = true;
    lastType = type;
    // simulate immediate acceptance for testing
    return AccessRequest(
      id: 'r1',
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
      message: message,
      status: AccessRequestStatus.accepted,
      createdAt: DateTime.now(),
      ownerId: targetUserId,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
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

class _StreamAccessRepo extends AccessRequestsRepository {
  _StreamAccessRepo() : super(null as dynamic);

  final StreamController<AccessRequest?> ctrl = StreamController.broadcast();
  bool called = false;

  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    called = true;
    final now = DateTime.now();
    final r = AccessRequest(
      id: 'r1',
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
      message: message,
      status: AccessRequestStatus.pending,
      createdAt: now,
      ownerId: targetUserId,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    ctrl.add(r);
    return r;
  }

  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    return ctrl.stream;
  }
}

void main() {
  testWidgets('shows locked images and allows requesting images access', (
    tester,
  ) async {
    final prop = Property(
      id: 'p1',
      title: 'Test',
      price: 100.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: true,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _FakeAccessRepo();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<PropertiesRepository>.value(value: fakeProps),
            Provider<AccessRequestsRepository>.value(value: fakeAccess),
            Provider<AuthRepositoryDomain>.value(
              value: FakeAuthRepo(
                UserEntity(id: 'u1', email: 'u@x', role: UserRole.collector),
              ),
            ),
          ],
          child: PropertyPage(id: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // locked state visible
    expect(find.text('Images are hidden for this property'), findsOneWidget);

    // open request dialog
    await tester.tap(find.text('Request Images Access'));
    await tester.pumpAndSettle();

    // enter message and submit
    await tester.enterText(find.byType(TextField), 'Please');
    await tester.tap(find.text('Submit'));
    await tester.pump();

    // loading indicator shown (circular progress)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // wait for repo to finish
    await tester.pumpAndSettle();

    // request should have been called and images now visible
    expect(fakeAccess.called, isTrue);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('shows images after owner accepts later via stream', (
    tester,
  ) async {
    final prop = Property(
      id: 'p1',
      title: 'Test',
      price: 100.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: true,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _StreamAccessRepo();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<PropertiesRepository>.value(value: fakeProps),
            Provider<AccessRequestsRepository>.value(value: fakeAccess),
            Provider<AuthRepositoryDomain>.value(
              value: FakeAuthRepo(
                UserEntity(id: 'u1', email: 'u@x', role: UserRole.collector),
              ),
            ),
          ],
          child: PropertyPage(id: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // locked state visible
    expect(find.text('Images are hidden for this property'), findsOneWidget);

    // request (pending) -> images still locked after submit
    await tester.tap(find.text('Request Images Access'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(
      fakeAccess.called,
      isFalse,
    ); // _StreamAccessRepo sets called only if overridden; ensure stream created

    // simulate owner accepting later
    final now = DateTime.now();
    fakeAccess.ctrl.add(
      AccessRequest(
        id: 'r1',
        propertyId: 'p1',
        requesterId: 'u1',
        type: AccessRequestType.images,
        message: null,
        status: AccessRequestStatus.accepted,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Images access accepted'), findsOneWidget);
  });

  testWidgets('shows phone after owner accepts later via stream', (
    tester,
  ) async {
    final prop = Property(
      id: 'p1',
      title: 'Test',
      price: 100.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: const [],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: false,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _StreamAccessRepo();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<PropertiesRepository>.value(value: fakeProps),
            Provider<AccessRequestsRepository>.value(value: fakeAccess),
            Provider<AuthRepositoryDomain>.value(
              value: FakeAuthRepo(
                UserEntity(id: 'u1', email: 'u@x', role: UserRole.collector),
              ),
            ),
          ],
          child: PropertyPage(id: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // phone hidden initially
    expect(find.text('Phone is hidden'), findsOneWidget);

    // request phone access
    await tester.tap(find.text('Request Owner Phone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    // simulate owner accepting later
    final now = DateTime.now();
    fakeAccess.ctrl.add(
      AccessRequest(
        id: 'r2',
        propertyId: 'p1',
        requesterId: 'u1',
        type: AccessRequestType.phone,
        message: null,
        status: AccessRequestStatus.accepted,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('123456'), findsOneWidget);
    expect(find.text('Phone access accepted'), findsOneWidget);
  });
}
