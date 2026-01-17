import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

void main() {
  final lockedCompany = Property(
    id: 'c1',
    title: 't',
    description: '',
    purpose: PropertyPurpose.sale,
    createdBy: 'owner1',
    ownerScope: PropertyOwnerScope.company,
    locationUrl: 'https://example.com',
    imageUrls: const [],
    isImagesHidden: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: PropertyStatus.active,
    isDeleted: false,
    ownerPhoneEncryptedOrHiddenStored: '123',
  );

  final lockedBroker = Property(
    id: 'b1',
    title: 't',
    description: '',
    purpose: PropertyPurpose.sale,
    createdBy: 'broker1',
    ownerScope: PropertyOwnerScope.broker,
    brokerId: 'broker1',
    locationUrl: 'https://example.com',
    imageUrls: const [],
    isImagesHidden: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: PropertyStatus.active,
    isDeleted: false,
    ownerPhoneEncryptedOrHiddenStored: '123',
  );

  test('owner sees locked phone/images for company properties only', () {
    expect(
      canBypassPhoneRestrictions(role: UserRole.owner, property: lockedCompany),
      true,
    );
    expect(
      canBypassImageRestrictions(role: UserRole.owner, property: lockedCompany),
      true,
    );
    expect(
      canBypassPhoneRestrictions(role: UserRole.owner, property: lockedBroker),
      false,
    );
    expect(
      canBypassImageRestrictions(role: UserRole.owner, property: lockedBroker),
      false,
    );
    expect(
      hasIntrinsicPropertyAccess(
        property: lockedCompany,
        userRole: UserRole.owner,
        userId: 'owner1',
      ),
      true,
    );
    expect(
      hasIntrinsicPropertyAccess(
        property: lockedBroker,
        userRole: UserRole.owner,
        userId: 'owner1',
      ),
      false,
    );
  });

  test('broker sees own broker-owned property phone/images', () {
    expect(
      hasIntrinsicPropertyAccess(
        property: lockedBroker,
        userRole: UserRole.broker,
        userId: 'broker1',
      ),
      true,
    );
    expect(
      canBypassPhoneRestrictions(role: UserRole.broker, property: lockedBroker),
      false,
    );
  });

  test('creators get intrinsic access within allowed scopes', () {
    final createdByBroker = Property(
      id: 'c2',
      title: 't',
      description: '',
      purpose: PropertyPurpose.sale,
      createdBy: 'broker1',
      ownerScope: PropertyOwnerScope.company,
      locationUrl: 'https://example.com',
      imageUrls: const [],
      isImagesHidden: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: PropertyStatus.active,
      isDeleted: false,
      ownerPhoneEncryptedOrHiddenStored: '123',
    );
    expect(
      hasIntrinsicPropertyAccess(
        property: createdByBroker,
        userRole: UserRole.broker,
        userId: 'broker1',
      ),
      true,
    );

    final createdByCollector = Property(
      id: 'c3',
      title: 't',
      description: '',
      purpose: PropertyPurpose.sale,
      createdBy: 'collector1',
      ownerScope: PropertyOwnerScope.company,
      locationUrl: 'https://example.com',
      imageUrls: const [],
      isImagesHidden: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: PropertyStatus.active,
      isDeleted: false,
      ownerPhoneEncryptedOrHiddenStored: '123',
    );
    expect(
      hasIntrinsicPropertyAccess(
        property: createdByCollector,
        userRole: UserRole.collector,
        userId: 'collector1',
      ),
      true,
    );

    final createdBrokerScopeByCollector = Property(
      id: 'c4',
      title: 't',
      description: '',
      purpose: PropertyPurpose.sale,
      createdBy: 'collector1',
      ownerScope: PropertyOwnerScope.broker,
      brokerId: 'broker1',
      locationUrl: 'https://example.com',
      imageUrls: const [],
      isImagesHidden: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: PropertyStatus.active,
      isDeleted: false,
      ownerPhoneEncryptedOrHiddenStored: '123',
    );
    expect(
      hasIntrinsicPropertyAccess(
        property: createdBrokerScopeByCollector,
        userRole: UserRole.collector,
        userId: 'collector1',
      ),
      true,
    );
  });

  test('edit allowed for owner and creator', () {
    expect(
      canModifyProperty(
        property: lockedCompany,
        userId: 'owner1',
        role: UserRole.owner,
      ),
      true,
    );
    expect(
      canModifyProperty(
        property: lockedCompany,
        userId: 'collector1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canModifyProperty(
        property: lockedCompany,
        userId: 'broker1',
        role: UserRole.broker,
      ),
      false,
    );
    expect(
      canModifyProperty(
        property: lockedCompany,
        userId: 'owner1',
        role: UserRole.owner,
      ),
      true,
    );
  });

  test('requesting sensitive info respects scope for collectors', () {
    expect(
      canRequestSensitiveInfo(
        role: UserRole.collector,
        property: lockedCompany,
      ),
      true,
    );
    expect(
      canRequestSensitiveInfo(role: UserRole.collector, property: lockedBroker),
      false,
    );
    expect(
      canRequestSensitiveInfo(role: UserRole.broker, property: lockedBroker),
      true,
    );
    expect(
      canRequestSensitiveInfo(role: UserRole.owner, property: lockedBroker),
      true,
    );
  });

  group('isCreatorWithFullAccess - ABSOLUTE RULE', () {
    test('broker creator has full access to their property', () {
      expect(
        isCreatorWithFullAccess(
          property: lockedBroker,
          userId: 'broker1',
          userRole: UserRole.broker,
        ),
        true,
        reason: 'Broker creator should have FULL access to their property',
      );
    });

    test('collector creator has full access to company-scoped property', () {
      expect(
        isCreatorWithFullAccess(
          property: lockedCompany,
          userId: 'owner1',
          userRole: UserRole.collector,
        ),
        true,
        reason:
            'Collector creator has full access when property is company-scoped',
      );
    });

    test('collector creator DOES have full access to broker-scoped property', () {
      // Edge case: collector somehow created a broker property (shouldn't happen,
      // but absolute creator rule must be honored)
      final brokerScoped = Property(
        id: 'b2',
        title: 't',
        description: '',
        purpose: PropertyPurpose.sale,
        createdBy: 'collector1',
        ownerScope: PropertyOwnerScope.broker,
        brokerId: 'broker1',
        locationUrl: 'https://example.com',
        imageUrls: const [],
        isImagesHidden: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: PropertyStatus.active,
        isDeleted: false,
        ownerPhoneEncryptedOrHiddenStored: '123',
      );
      expect(
        isCreatorWithFullAccess(
          property: brokerScoped,
          userId: 'collector1',
          userRole: UserRole.collector,
        ),
        true,
        reason: 'Creators ALWAYS have full access to properties they created',
      );
    });

    test('non-creator never has full creator access', () {
      expect(
        isCreatorWithFullAccess(
          property: lockedBroker,
          userId: 'other-user',
          userRole: UserRole.broker,
        ),
        false,
        reason: 'Non-creator should not get creator full access',
      );
    });

    test('owner creator has full access', () {
      expect(
        isCreatorWithFullAccess(
          property: lockedCompany,
          userId: 'owner1',
          userRole: UserRole.owner,
        ),
        true,
        reason: 'Owner creator should have FULL access',
      );
    });
  });
}
