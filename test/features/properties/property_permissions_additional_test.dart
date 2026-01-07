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

  test('owner always sees locked phone/images', () {
    expect(canBypassPhoneRestrictions(UserRole.owner), true);
    expect(canBypassImageRestrictions(UserRole.owner), true);
    expect(
      hasIntrinsicPropertyAccess(
        property: lockedCompany,
        userRole: UserRole.owner,
        userId: 'owner1',
      ),
      true,
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
    expect(canBypassPhoneRestrictions(UserRole.broker), false);
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
        userId: 'owner1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canModifyProperty(
        property: lockedCompany,
        userId: 'owner1',
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
}
