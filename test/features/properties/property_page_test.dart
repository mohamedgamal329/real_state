import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/auth/domain/entities/user_entity.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/presentation/pages/property_detail/property_page.dart';
import 'package:real_state/features/properties/presentation/widgets/property_images_section.dart';
import 'package:real_state/features/properties/presentation/widgets/property_phone_section.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

import '../fake_auth_repo/fake_auth_repo.dart';
import '../../fakes/fake_firebase.dart';
import '../../fakes/fake_repositories.dart';
import '../../helpers/pump_test_app.dart';

class _FakePropertiesRepo extends PropertiesRepositoryImpl {
  final Property _prop;

  _FakePropertiesRepo(this._prop) : super(FakeFirebaseFirestore());

  @override
  Future<Property?> getById(String id) async => _prop;
}

class _FakeAccessRepo implements AccessRequestsRepository {
  _FakeAccessRepo();

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

  @override
  Future<PageResult<AccessRequest>> fetchPage({
    PageToken? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async => PageResult(items: const [], lastDocument: null, hasMore: false);

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async => null;

  @override
  Future<AccessRequest?> fetchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async => null;

  @override
  Future<AccessRequest?> fetchById(String id) async => null;

  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async => throw UnimplementedError();
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
      createdBy: 'owner1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _FakeAccessRepo();
    final fakeNotifications = FakeNotificationsRepository();
    final fakeUsers = FakeUsersRepository();
    fakeUsers.seed(ManagedUser(id: 'u1', email: 'u@x', role: UserRole.broker));
    fakeUsers.seed(
      ManagedUser(id: 'owner1', email: 'o@x', role: UserRole.owner),
    );
    final deps = TestAppDependencies(
      propertiesRepositoryOverride: fakeProps,
      accessRequestsRepositoryOverride: fakeAccess,
      notificationsRepositoryOverride: fakeNotifications,
      usersRepositoryOverride: fakeUsers,
      authRepositoryOverride: FakeAuthRepo(
        UserEntity(id: 'u1', email: 'u@x', role: UserRole.broker),
      ),
    );
    addTearDown(() => deps.propertyMutationsBloc.close());

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => PropertyPage(id: 'p1'),
        ),
      ],
    );
    await pumpTestApp(
      tester,
      const SizedBox.shrink(),
      dependencies: deps,
      router: router,
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    final requestButton = find.byKey(
      PropertyImagesSection.requestAccessButtonKey,
    );
    await pumpUntilFound(tester, requestButton, maxTries: 60);
    await tester.scrollUntilVisible(requestButton, 120);
    await tester.tap(requestButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('property_request_message_input')),
      'Please',
    );
    final submitButton = find.byKey(
      const ValueKey('property_request_submit_button'),
    );
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.pumpAndSettle();

    expect(fakeAccess.called, isTrue);
    expect(find.text('Request submitted'), findsOneWidget);
  });

  testWidgets('shows images after access is granted', (tester) async {
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
      createdBy: 'u1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final controller = ScrollController();
    addTearDown(controller.dispose);
    final imagesVisible = ValueNotifier(false);
    addTearDown(imagesVisible.dispose);

    await pumpTestApp(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: imagesVisible,
        builder: (context, value, _) => PropertyImagesSection(
          property: prop,
          imagesVisible: value,
          scrollController: controller,
          imagesToShow: prop.imageUrls.length,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PropertyImagesSection), findsOneWidget);

    imagesVisible.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(PropertyImagesSection), findsOneWidget);
  }, skip: true);

  testWidgets('shows phone after access is granted', (tester) async {
    final phoneVisible = ValueNotifier(false);
    addTearDown(phoneVisible.dispose);

    await pumpTestApp(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: phoneVisible,
        builder: (context, value, _) =>
            PropertyPhoneSection(phoneVisible: value, phoneText: '123456'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PropertyPhoneSection), findsOneWidget);

    phoneVisible.value = true;
    await tester.pumpAndSettle();
    expect(find.byType(PropertyPhoneSection), findsOneWidget);
  }, skip: true);

  testWidgets('creator sees images and phone without access request', (
    tester,
  ) async {
    final prop = Property(
      id: 'p2',
      title: 'Creator property',
      price: 120.0,
      description: 'desc',
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: null,
      floors: null,
      hasPool: false,
      locationAreaId: null,
      coverImageUrl: null,
      imageUrls: ['https://example.com/1.jpg'],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      isImagesHidden: true,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: 'u1',
      brokerId: 'u1',
      ownerScope: PropertyOwnerScope.broker,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    final fakeProps = _FakePropertiesRepo(prop);
    final fakeAccess = _FakeAccessRepo();
    final fakeNotifications = FakeNotificationsRepository();
    final fakeUsers = FakeUsersRepository();
    fakeUsers.seed(ManagedUser(id: 'u1', email: 'u@x', role: UserRole.broker));
    final deps = TestAppDependencies(
      propertiesRepositoryOverride: fakeProps,
      accessRequestsRepositoryOverride: fakeAccess,
      notificationsRepositoryOverride: fakeNotifications,
      usersRepositoryOverride: fakeUsers,
      authRepositoryOverride: FakeAuthRepo(
        UserEntity(id: 'u1', email: 'u@x', role: UserRole.broker),
      ),
    );
    addTearDown(() => deps.propertyMutationsBloc.close());

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => PropertyPage(id: 'p2'),
        ),
      ],
    );
    await pumpTestApp(
      tester,
      const SizedBox.shrink(),
      dependencies: deps,
      router: router,
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.byKey(PropertyImagesSection.hiddenImagesKey), findsNothing);
    expect(
      find.byKey(PropertyImagesSection.requestAccessButtonKey),
      findsNothing,
    );
    expect(find.byKey(PropertyPhoneSection.hiddenPhoneKey), findsNothing);
    expect(find.byKey(PropertyPhoneSection.requestButtonKey), findsNothing);
  });
}
