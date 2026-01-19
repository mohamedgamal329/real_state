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
/// Owners are always allowed. Brokers/Collectors can modify properties they created.
bool canModifyProperty({
  required Property property,
  required String userId,
  required UserRole role,
}) {
  if (role == UserRole.owner) return true;
  if (property.createdBy == userId) return true;
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

/// ABSOLUTE RULE: Returns true if user is the property creator OR Company Owner.
/// When true, user should NEVER see:
/// - Request access buttons
/// - Locked placeholders
/// - Permission warnings
bool hasIntrinsicPropertyAccess({
  required Property property,
  required UserRole? userRole,
  required String? userId,
}) {
  if (userRole == UserRole.owner) {
    // Owners have full access to company properties.
    if (property.ownerScope == PropertyOwnerScope.company) return true;
    // For broker properties, owner needs to request access (verified by tests).
    // Unless they are the creator of this specific property.
    if (userId != null && property.createdBy == userId) return true;
    return false;
  }
  if (userId != null && property.createdBy == userId) return true;
  if (userRole == UserRole.broker && userId != null) {
    if (property.brokerId == userId) return true;
  }
  return false;
}

/// Owners and Creators can bypass visibility restrictions.
bool canBypassImageRestrictions({
  required UserRole? role,
  required Property property,
  String? userId,
}) => hasIntrinsicPropertyAccess(
  property: property,
  userRole: role,
  userId: userId,
);

bool canBypassPhoneRestrictions({
  required UserRole? role,
  required Property property,
  String? userId,
}) => hasIntrinsicPropertyAccess(
  property: property,
  userRole: role,
  userId: userId,
);

bool canBypassLocationRestrictions({
  required UserRole? role,
  required Property property,
  String? userId,
}) => hasIntrinsicPropertyAccess(
  property: property,
  userRole: role,
  userId: userId,
);

/// Determine if user can Request access.
/// Returns false for creators/owners since they have intrinsic access.
bool canRequestSensitiveInfo({
  required UserRole? role,
  required String? userId,
  required Property property,
}) {
  if (role == null) return false;
  if (hasIntrinsicPropertyAccess(
    property: property,
    userRole: role,
    userId: userId,
  )) {
    return false;
  }
  // Collectors can only request for company properties.
  if (role == UserRole.collector) {
    return property.ownerScope == PropertyOwnerScope.company;
  }
  // Owners can request for anything they don't have intrinsic access to (e.g. broker props).
  if (role == UserRole.owner) return true;
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
  return request.ownerId == userId || role == UserRole.owner;
}

bool isPropertyCreator({required Property property, required String? userId}) {
  if (userId == null || userId.isEmpty) return false;
  return property.createdBy == userId;
}

/// Returns true if the user can view the security number (security guard phone).
bool canViewSecurityNumber({
  required Property property,
  required String? userId,
  required UserRole? userRole,
  bool hasAcceptedRequest = false,
}) {
  if (hasIntrinsicPropertyAccess(
    property: property,
    userRole: userRole,
    userId: userId,
  )) {
    return true;
  }
  return hasAcceptedRequest;
}

/// Legacy alias for hasIntrinsicPropertyAccess targeted at UI checks.
bool isCreatorWithFullAccess({
  required Property property,
  required String? userId,
  required UserRole? userRole,
}) => hasIntrinsicPropertyAccess(
  property: property,
  userRole: userRole,
  userId: userId,
);
