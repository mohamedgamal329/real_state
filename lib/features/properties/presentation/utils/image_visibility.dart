import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/auth/current_user_accessor.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

/// Central place to decide whether images for a property should be rendered.
/// Always honor [override] when provided (e.g., detail page access state).
/// This keeps image widgets from being created when visibility is denied, which
/// avoids accidental leaks through caching or reused widgets.
bool canViewPropertyImages({
  required BuildContext context,
  required Property property,
  bool? override,
}) {
  if (override != null) return override;
  final accessor = Provider.of<CurrentUserAccessor?>(context, listen: false);
  final role = accessor?.currentRole;
  if (role == UserRole.owner &&
      property.ownerScope == PropertyOwnerScope.broker) {
    return false;
  }
  // Deny by default when role is unavailable to avoid privacy leaks.
  return role != null;
}
