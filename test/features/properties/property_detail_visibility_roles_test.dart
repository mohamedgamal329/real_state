import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_state.dart';

Property _buildProperty({
  required PropertyOwnerScope scope,
  required String createdBy,
  String? brokerId,
  bool isImagesHidden = true,
}) {
  return Property(
    id: 'p1',
    title: 't',
    description: '',
    purpose: PropertyPurpose.sale,
    createdBy: createdBy,
    ownerScope: scope,
    brokerId: brokerId,
    isImagesHidden: isImagesHidden,
    locationUrl: 'https://example.com',
    ownerPhoneEncryptedOrHiddenStored: '0500000000',
    status: PropertyStatus.active,
    isDeleted: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  test('owner needs access for broker-scoped hidden fields', () {
    final property = _buildProperty(
      scope: PropertyOwnerScope.broker,
      createdBy: 'broker1',
      brokerId: 'broker1',
      isImagesHidden: true,
    );
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'owner1',
      userRole: UserRole.owner,
      imagesToShow: 0,
    );

    expect(state.imagesVisible, isFalse);
    expect(state.phoneVisible, isFalse);
    expect(state.locationVisible, isFalse);
  });

  test('broker sees own broker-scoped hidden fields', () {
    final property = _buildProperty(
      scope: PropertyOwnerScope.broker,
      createdBy: 'broker1',
      brokerId: 'broker1',
      isImagesHidden: true,
    );
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'broker1',
      userRole: UserRole.broker,
      imagesToShow: 0,
    );

    expect(state.imagesVisible, isTrue);
    expect(state.phoneVisible, isTrue);
    expect(state.locationVisible, isTrue);
  });

  test('collector can see company property they created', () {
    final property = _buildProperty(
      scope: PropertyOwnerScope.company,
      createdBy: 'collector1',
      isImagesHidden: true,
    );
    final state = PropertyDetailLoaded(
      property: property,
      userId: 'collector1',
      userRole: UserRole.collector,
      imagesToShow: 0,
    );

    expect(state.imagesVisible, isTrue);
    expect(state.phoneVisible, isTrue);
    expect(state.locationVisible, isTrue);
  });
}
