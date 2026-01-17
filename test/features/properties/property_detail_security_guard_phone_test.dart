import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_state.dart';

void main() {
  Property _buildProperty({required String createdBy}) {
    return Property(
      id: 'p1',
      title: 'Test',
      description: 'desc',
      purpose: PropertyPurpose.sale,
      hasPool: false,
      ownerScope: PropertyOwnerScope.company,
      createdBy: createdBy,
      securityGuardPhoneEncryptedOrHiddenStored: '0500000000',
      status: PropertyStatus.active,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  test('creator can see security guard phone', () {
    final property = _buildProperty(createdBy: 'u1');
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'u1',
      userRole: UserRole.owner,
      imagesToShow: 0,
    );

    expect(state.hasSecurityGuardPhone, isTrue);
    expect(state.securityGuardPhoneVisible, isTrue);
  });

  test('user without access cannot see security guard phone', () {
    final property = _buildProperty(createdBy: 'u1');
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'u2',
      userRole: UserRole.broker,
      imagesToShow: 0,
    );

    expect(state.securityGuardPhoneVisible, isFalse);
  });

  test('security guard phone shows after access granted', () {
    final property = _buildProperty(createdBy: 'u1');
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'u2',
      userRole: UserRole.broker,
      imagesToShow: 0,
      phoneAccessGranted: true,
    );

    expect(state.securityGuardPhoneVisible, isTrue);
  });
}
