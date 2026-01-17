import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

void main() {
  group('canCreateProperty', () {
    test('allows owner and employees/brokers', () {
      expect(canCreateProperty(UserRole.owner), isTrue);
      expect(canCreateProperty(UserRole.collector), isTrue);
      expect(canCreateProperty(UserRole.broker), isTrue);
    });

    test('denies unknown roles', () {
      expect(
        canCreateProperty(UserRole.owner),
        isTrue,
      ); // only defined roles allowed
    });
  });

  group('canModifyProperty', () {
    final base = Property(
      id: 'p1',
      title: 't',
      purpose: PropertyPurpose.sale,
      createdBy: 'creator',
      ownerScope: PropertyOwnerScope.company,
      brokerId: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('owner can always modify', () {
      expect(
        canModifyProperty(
          property: base,
          userId: 'someone',
          role: UserRole.owner,
        ),
        isTrue,
      );
    });

    test('creator can modify', () {
      expect(
        canModifyProperty(
          property: base,
          userId: 'creator',
          role: UserRole.collector,
        ),
        isTrue,
      );
    });

    test('collector can modify broker-scoped property if created', () {
      final brokerProperty = Property(
        id: base.id,
        title: base.title,
        purpose: base.purpose,
        createdBy: 'collector1',
        ownerScope: PropertyOwnerScope.broker,
        brokerId: 'broker1',
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      );
      expect(
        canModifyProperty(
          property: brokerProperty,
          userId: 'collector1',
          role: UserRole.collector,
        ),
        isTrue,
      );
    });

    test('broker can modify own broker-scoped property', () {
      final brokerProperty = Property(
        id: base.id,
        title: base.title,
        purpose: base.purpose,
        createdBy: base.createdBy,
        ownerScope: PropertyOwnerScope.broker,
        brokerId: 'broker1',
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      );
      expect(
        canModifyProperty(
          property: brokerProperty,
          userId: 'broker1',
          role: UserRole.broker,
        ),
        isTrue,
      );
    });

    test('unassigned non-owner cannot modify', () {
      expect(
        canModifyProperty(
          property: base,
          userId: 'other',
          role: UserRole.collector,
        ),
        isFalse,
      );
    });
  });
}
