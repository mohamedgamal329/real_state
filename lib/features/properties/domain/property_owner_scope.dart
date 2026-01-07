import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';

enum PropertyOwnerScope { company, broker }

PropertyOwnerScope resolveOwnerScopeByRole(UserRole role) {
  return role == UserRole.broker
      ? PropertyOwnerScope.broker
      : PropertyOwnerScope.company;
}

bool isBrokerOwned(Property property) =>
    property.ownerScope == PropertyOwnerScope.broker;

bool isCompanyOwned(Property property) =>
    property.ownerScope == PropertyOwnerScope.company;
