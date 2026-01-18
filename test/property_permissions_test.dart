import 'package:flutter_test/flutter_test.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

void main() {
  final companyProperty = Property(
    id: 'p1',
    title: 't',
    description: '',
    purpose: PropertyPurpose.rent,
    createdBy: 'u1',
    ownerScope: PropertyOwnerScope.company,
    locationUrl: '',
    imageUrls: const [],
    isImagesHidden: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: PropertyStatus.active,
    isDeleted: false,
  );
  final brokerProperty = Property(
    id: 'p2',
    title: 't',
    description: '',
    purpose: PropertyPurpose.rent,
    createdBy: 'u1',
    ownerScope: PropertyOwnerScope.broker,
    brokerId: 'b1',
    locationUrl: '',
    imageUrls: const [],
    isImagesHidden: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    status: PropertyStatus.active,
    isDeleted: false,
  );

  test('collector cannot archive or delete any property', () {
    expect(
      canArchiveOrDeleteProperty(
        property: companyProperty,
        userId: 'u1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canArchiveProperty(
        property: companyProperty,
        userId: 'u1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canDeleteProperty(
        property: companyProperty,
        userId: 'u1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canArchiveOrDeleteProperty(
        property: brokerProperty,
        userId: 'u1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canArchiveProperty(
        property: brokerProperty,
        userId: 'u1',
        role: UserRole.collector,
      ),
      false,
    );
    expect(
      canDeleteProperty(
        property: brokerProperty,
        userId: 'u1',
        role: UserRole.collector,
      ),
      false,
    );
  });

  test('collector cannot access broker flows', () {
    expect(canSeeBrokersSection(UserRole.collector), false);
    expect(canAccessBrokersRoutes(UserRole.collector), false);
    expect(canViewBrokerFlows(UserRole.collector), false);
  });

  test('collector cannot accept/reject access requests', () {
    expect(canAcceptRejectAccessRequests(UserRole.collector), false);
    expect(canRequestAccess(UserRole.collector), true);
    expect(canManageUsers(UserRole.collector), false);
    expect(canManageLocations(UserRole.collector), false);
    expect(canShowAccessRequestDialog(UserRole.collector), false);
  });

  group('Security Number Permissions', () {
    test('creator can always view security number', () {
      expect(
        canViewSecurityNumber(
          property: companyProperty,
          userId: 'u1', // Created by u1
          userRole: UserRole.broker,
        ),
        true,
      );
    });

    test(
      'collector can view security number of company property they created',
      () {
        expect(
          canViewSecurityNumber(
            property: companyProperty,
            userId: 'u1', // Created by u1
            userRole: UserRole.collector,
          ),
          true,
        );
      },
    );

    test(
      'collector cannot view security number of broker property they did not create',
      () {
        expect(
          canViewSecurityNumber(
            property: brokerProperty,
            userId: 'other',
            userRole: UserRole.collector,
          ),
          false,
        );
      },
    );

    test('owner can always view security number of company properties', () {
      expect(
        canViewSecurityNumber(
          property: companyProperty,
          userId: 'any',
          userRole: UserRole.owner,
        ),
        true,
      );
    });

    test('other user can view only with accepted request', () {
      expect(
        canViewSecurityNumber(
          property: companyProperty,
          userId: 'u2',
          userRole: UserRole.broker,
        ),
        false,
      );
      expect(
        canViewSecurityNumber(
          property: companyProperty,
          userId: 'u2',
          userRole: UserRole.broker,
          hasAcceptedRequest: true,
        ),
        true,
      );
    });

    test('creator cannot request sensitive info for their own property', () {
      expect(
        canRequestSensitiveInfo(
          property: companyProperty,
          userId: 'u1',
          role: UserRole.broker,
        ),
        false,
      );
    });

    test('others can request sensitive info if they have no full access', () {
      expect(
        canRequestSensitiveInfo(
          property: companyProperty,
          userId: 'u2',
          role: UserRole.broker,
        ),
        true,
      );
    });
  });
}
