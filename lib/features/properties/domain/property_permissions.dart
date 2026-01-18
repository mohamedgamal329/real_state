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
bool canRequestAccess(UserRole? role) => role != null;
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
  if (property.createdBy == userId) return true;
  if (role == UserRole.owner) return true;
  if (role == UserRole.broker && property.brokerId == userId) return true;
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

/// Owners can bypass image visibility restrictions for company properties.
bool canBypassImageRestrictions({
  required UserRole? role,
  required Property property,
}) =>
    role == UserRole.owner && property.ownerScope == PropertyOwnerScope.company;

/// Owners can bypass phone visibility restrictions for company properties.
bool canBypassPhoneRestrictions({
  required UserRole? role,
  required Property property,
}) =>
    role == UserRole.owner && property.ownerScope == PropertyOwnerScope.company;

/// Owners can bypass location visibility restrictions for company properties.
bool canBypassLocationRestrictions({
  required UserRole? role,
  required Property property,
}) =>
    role == UserRole.owner && property.ownerScope == PropertyOwnerScope.company;

/// Collectors can request sensitive data for company properties only.
bool canRequestSensitiveInfo({
  required UserRole? role,
  required String? userId,
  required Property property,
}) {
  if (role == null) return false;
  if (isCreatorWithFullAccess(
    property: property,
    userId: userId,
    userRole: role,
  )) {
    return false;
  }
  if (role == UserRole.collector) {
    return property.ownerScope == PropertyOwnerScope.company;
  }
  return true;
}

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

bool isPropertyCreator({required Property property, required String? userId}) {
  if (userId == null || userId.isEmpty) return false;
  return property.createdBy == userId;
}

/// Determines if a user inherently has access to hidden details for a property.
/// - Owners always have access to company properties.
/// - Brokers have access to properties they created/own.
/// - Collectors have access to company properties they created.
bool hasIntrinsicPropertyAccess({
  required Property property,
  required UserRole? userRole,
  required String? userId,
}) {
  if (userId != null && property.createdBy == userId) return true;
  if (userRole == UserRole.owner) {
    return property.ownerScope == PropertyOwnerScope.company;
  }
  if (userRole == UserRole.broker && userId != null) {
    return property.brokerId == userId || property.createdBy == userId;
  }
  if (userRole == UserRole.collector && userId != null) {
    if (property.ownerScope != PropertyOwnerScope.company) return false;
    return property.createdBy == userId;
  }
  return false;
}

/// Returns true if the user can view the security number (security guard phone).
bool canViewSecurityNumber({
  required Property property,
  required String? userId,
  required UserRole? userRole,
  bool hasAcceptedRequest = false,
}) {
  if (isCreatorWithFullAccess(
    property: property,
    userId: userId,
    userRole: userRole,
  )) {
    return true;
  }
  if (hasIntrinsicPropertyAccess(
    property: property,
    userRole: userRole,
    userId: userId,
  )) {
    return true;
  }
  return hasAcceptedRequest;
}

/// ABSOLUTE RULE: Returns true if user is the property creator AND has FULL access.
///
/// When true, creator should NEVER see:
/// - Request access buttons
/// - Locked placeholders
/// - Permission warnings
/// - Any restricted UI
///
/// Use this function as the SINGLE SOURCE OF TRUTH for creator access checks in UI.
bool isCreatorWithFullAccess({
  required Property property,
  required String? userId,
  required UserRole? userRole,
}) {
  if (userId == null || userId.isEmpty) return false;
  return property.createdBy == userId;
}
