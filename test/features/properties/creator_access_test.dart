import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/presentation/bloc/detail/property_detail_state.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

void main() {
  group('FIX 4: Creator Full Access Absolute Rule', () {
    final creatorId = 'user-creator';
    final otherId = 'user-other';

    final property = Property(
      id: 'prop-1',
      title: 'Title',
      description: 'Desc',
      price: 1000,
      purpose: PropertyPurpose.sale,
      rooms: 2,
      kitchens: 1,
      floors: 1,
      hasPool: false,
      locationAreaId: 'loc-1',
      imageUrls: ['http://img.com/1.jpg'],
      ownerPhoneEncryptedOrHiddenStored: '123456',
      securityGuardPhoneEncryptedOrHiddenStored: '999999',
      locationUrl: 'http://maps.com',
      isImagesHidden: true, // Hidden by default
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: creatorId,
      ownerScope: PropertyOwnerScope.company,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      updatedBy: null,
    );

    test('isCreatorWithFullAccess returns true for creator', () {
      expect(
        isCreatorWithFullAccess(
          property: property,
          userId: creatorId,
          userRole: UserRole.broker,
        ),
        isTrue,
      );
      expect(
        isCreatorWithFullAccess(
          property: property,
          userId: creatorId,
          userRole: UserRole.owner,
        ),
        isTrue,
      );
      expect(
        isCreatorWithFullAccess(
          property: property,
          userId: creatorId,
          userRole: UserRole.collector,
        ),
        isTrue,
      );
    });

    test('isCreatorWithFullAccess returns false for others', () {
      expect(
        isCreatorWithFullAccess(
          property: property,
          userId: otherId,
          userRole: UserRole.broker,
        ),
        isFalse,
      );
      expect(
        isCreatorWithFullAccess(
          property: property,
          userId: null,
          userRole: null,
        ),
        isFalse,
      );
    });

    test(
      'PropertyDetailState.imagesVisible is TRUE for creator even if hidden',
      () {
        final state = PropertyDetailLoaded(
          property: property,
          imagesToShow: 3,
          userId: creatorId,
          userRole: UserRole.broker,
          imagesAccessGranted: false, // Explicitly false
          phoneAccessGranted: false,
        );

        // Should be visible because of absolute rule
        expect(state.imagesVisible, isTrue);
      },
    );

    test('PropertyDetailState.phoneVisible is TRUE for creator', () {
      final state = PropertyDetailLoaded(
        property: property,
        imagesToShow: 3,
        userId: creatorId,
        userRole: UserRole.broker,
        imagesAccessGranted: false,
        phoneAccessGranted: false, // Explicitly false
      );

      // Should be visible
      expect(state.phoneVisible, isTrue);
    });

    test(
      'PropertyDetailState.securityGuardPhoneVisible is TRUE for creator',
      () {
        final state = PropertyDetailLoaded(
          property: property,
          imagesToShow: 3,
          userId: creatorId,
          userRole: UserRole.broker,
          imagesAccessGranted: false,
          phoneAccessGranted: false,
        );

        // Should be visible
        expect(state.hasSecurityGuardPhone, isTrue);
        expect(state.securityGuardPhoneVisible, isTrue);
      },
    );

    test('PropertyDetailState.locationVisible is TRUE for creator', () {
      final state = PropertyDetailLoaded(
        property: property,
        imagesToShow: 3,
        userId: creatorId,
        userRole: UserRole.broker,
        locationAccessGranted: false,
      );

      expect(state.locationVisible, isTrue);
    });
  });
}
