import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_state.dart';

void main() {
  Property _buildProperty({required String createdBy, String? securityNumber}) {
    return Property(
      id: 'p1',
      title: 'Test',
      description: 'desc',
      purpose: PropertyPurpose.sale,
      hasPool: false,
      ownerScope: PropertyOwnerScope.company,
      createdBy: createdBy,
      securityNumberEncryptedOrHiddenStored: securityNumber,
      status: PropertyStatus.active,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  test('creator can see security number', () {
    final property = _buildProperty(createdBy: 'u1', securityNumber: 'S123');
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'u1',
      userRole: UserRole.owner,
      imagesToShow: 0,
    );

    expect(state.hasSecurityNumber, isTrue);
    expect(state.securityNumberVisible, isTrue);
  });

  test('user without access cannot see security number', () {
    final property = _buildProperty(createdBy: 'u1', securityNumber: 'S123');
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'u2',
      userRole: UserRole.broker,
      imagesToShow: 0,
    );

    expect(state.securityNumberVisible, isFalse);
  });

  test('security number shows after access granted', () {
    final property = _buildProperty(createdBy: 'u1', securityNumber: 'S123');
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'u2',
      userRole: UserRole.broker,
      imagesToShow: 0,
      phoneAccessGranted: true,
    );

    expect(state.securityNumberVisible, isTrue);
  });

  group('Security Number State', () {
    test('reflects hasSecurityNumber correctly', () {
      final p1 = _buildProperty(createdBy: 'u1', securityNumber: 'S-123');
      final s1 = PropertyDetailLoaded(
        property: p1,
        userId: 'any',
        userRole: UserRole.broker,
        imagesToShow: 0,
      );
      expect(s1.hasSecurityNumber, isTrue);

      final p2 = _buildProperty(createdBy: 'u1', securityNumber: null);
      final s2 = PropertyDetailLoaded(
        property: p2,
        userId: 'any',
        userRole: UserRole.broker,
        imagesToShow: 0,
      );
      expect(s2.hasSecurityNumber, isFalse);
    });

    test('creator can see security number', () {
      final property = _buildProperty(createdBy: 'u1', securityNumber: 'S-123');
      final state = PropertyDetailLoaded(
        property: property,
        userId: 'u1',
        userRole: UserRole.broker,
        imagesToShow: 0,
      );
      expect(state.securityNumberVisible, isTrue);
    });

    test('others cannot see security number without access granted', () {
      final property = _buildProperty(createdBy: 'u1', securityNumber: 'S-123');
      final state = PropertyDetailLoaded(
        property: property,
        userId: 'u2',
        userRole: UserRole.broker,
        imagesToShow: 0,
      );
      expect(state.securityNumberVisible, isFalse);
    });

    test('security number shows after phone access granted', () {
      final property = _buildProperty(createdBy: 'u1', securityNumber: 'S-123');
      final state = PropertyDetailLoaded(
        property: property,
        userId: 'u2',
        userRole: UserRole.broker,
        imagesToShow: 0,
        phoneAccessGranted: true,
      );
      expect(state.securityNumberVisible, isTrue);
    });
  });
}
