import '../../models/entities/property.dart';
import '../../../core/constants/user_role.dart';
import '../../models/entities/access_request.dart';
import 'property_owner_scope.dart';

const _creatorRoles = {UserRole.owner, UserRole.broker, UserRole.collector};

/// Returns true when the role is allowed to create new properties.
bool canCreateProperty(UserRole role) => _creatorRoles.contains(role);

/// Core collector restrictions (single source of truth).
bool canSeeBrokersSection(UserRole? role) => role != UserRole.collector;
bool canAccessBrokersRoutes(UserRole? role) => role != UserRole.collector;
bool canManageUsers(UserRole? role) => role == UserRole.owner;
bool canManageLocations(UserRole? role) =>
    role == UserRole.owner || role == UserRole.broker;
bool canAcceptRejectAccessRequests(UserRole? role) =>
    role == UserRole.owner || role == UserRole.broker;
bool canRequestAccess(UserRole? role) =>
    role != UserRole.collector && role != null;
bool canShowAccessRequestDialog(UserRole? role) =>
    canAcceptRejectAccessRequests(role);

/// Collectors can edit company-scoped properties they created.
bool canCollectorEditCompanyProperty({
  required Property property,
  required UserRole role,
  required String userId,
}) {
  if (role != UserRole.collector) return false;
  return property.ownerScope == PropertyOwnerScope.company &&
      property.createdBy == userId;
}

bool canViewBrokerOwnedProperties(UserRole? role) => role != UserRole.collector;
bool canViewBrokerFlows(UserRole? role) => role != UserRole.collector;
bool canCollectorViewCompanyOnly(UserRole? role) => role == UserRole.collector;
bool canCollectorMutateCompanyProperty(Property property, UserRole? role) =>
    role == UserRole.collector &&
    property.ownerScope == PropertyOwnerScope.company;

/// Returns true when the user can update/archive/delete the given property.
/// Owners are always allowed. Brokers can modify their own properties.
/// Collectors can modify properties they created.
bool canModifyProperty({
  required Property property,
  required String userId,
  required UserRole role,
}) {
  if (role == UserRole.owner) return true;
  if (role == UserRole.broker && property.brokerId == userId) return true;
  if (role == UserRole.collector) {
    return canCollectorEditCompanyProperty(
      property: property,
      role: role,
      userId: userId,
    );
  }
  if (property.createdBy == userId && role != UserRole.collector) return true;
  return false;
}

/// Collectors cannot delete/archive; owners and brokers can delete/archive their own.
bool canArchiveOrDeleteProperty({
  required Property property,
  required String userId,
  required UserRole role,
}) {
  if (role == UserRole.collector) return false;
  return canModifyProperty(property: property, userId: userId, role: role);
}

bool canArchiveProperty({
  required Property property,
  required String userId,
  required UserRole role,
}) =>
    canArchiveOrDeleteProperty(property: property, userId: userId, role: role);

bool canDeleteProperty({
  required Property property,
  required String userId,
  required UserRole role,
}) =>
    canArchiveOrDeleteProperty(property: property, userId: userId, role: role);

/// Owners can always bypass image visibility restrictions.
bool canBypassImageRestrictions(UserRole? role) => role == UserRole.owner;

/// Owners can always bypass phone visibility restrictions.
bool canBypassPhoneRestrictions(UserRole? role) => role == UserRole.owner;

/// Owners can always bypass location visibility restrictions.
bool canBypassLocationRestrictions(UserRole? role) => role == UserRole.owner;

/// Collectors are not allowed to request sensitive data (images/phone/location).
bool canRequestSensitiveInfo(UserRole? role) => canRequestAccess(role);

/// Collectors are not allowed to share properties.
bool canShareProperty(UserRole? role) =>
    role != UserRole.collector && role != null;

bool canDecideAccessRequest({
  required AccessRequest request,
  required String userId,
  required UserRole? role,
}) {
  if (role == UserRole.collector) return false;
  if (request.ownerId == null || request.ownerId!.isEmpty) return false;
  return request.ownerId == userId;
}

/// Determines if a user inherently has access to hidden details for a property.
/// - Owners always have access.
/// - Brokers have access to properties they created/own.
bool hasIntrinsicPropertyAccess({
  required Property property,
  required UserRole? userRole,
  required String? userId,
}) {
  if (userRole == UserRole.owner) return true;
  if (userRole == UserRole.broker &&
      userId != null &&
      property.brokerId == userId) {
    return true;
  }
  return false;
}
