import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

/// Resolves who should receive an access request for a property.
/// - If the property was created by a broker, the broker is the target.
/// - Otherwise the active company owner is the target (fallbacks to any owner).
/// The returned id is never null; it falls back to the property creator if no owner is found.
class ResolveAccessRequestTargetUseCase {
  ResolveAccessRequestTargetUseCase(this._usersRepository);

  final UsersRepository _usersRepository;
  String? _cachedOwnerId;

  Future<String> resolveTarget(Property property) async {
    if (property.ownerScope == PropertyOwnerScope.broker) {
      final brokerId = property.brokerId ?? property.createdBy;
      final broker = await _fetchUserSafely(brokerId);
      if (broker != null && broker.role == UserRole.broker) {
        return broker.id;
      }
      throw const LocalizedException('access_request_target_missing');
    }

    final ownerId = await _resolveOwnerId();
    if (ownerId != null && ownerId.isNotEmpty) return ownerId;
    throw const LocalizedException('access_request_target_missing');
  }

  Future<String?> _resolveOwnerId() async {
    if (_cachedOwnerId != null) return _cachedOwnerId;
    final owners = await _usersRepository.fetchUsers(role: UserRole.owner);
    ManagedUser? activeOwner;
    for (final u in owners) {
      if (u.active) {
        activeOwner = u;
        break;
      }
    }
    activeOwner ??= owners.isNotEmpty ? owners.first : null;
    _cachedOwnerId = activeOwner?.id;
    return _cachedOwnerId;
  }

  Future<ManagedUser?> _fetchUserSafely(String id) async {
    try {
      return await _usersRepository.getById(id);
    } catch (_) {
      return null;
    }
  }
}
