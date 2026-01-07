import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

/// Resolves which users should receive a "property added" notification.
/// Rules:
/// - Company-owned: owners + collectors + brokers (active only)
/// - Broker-owned: owner + the broker who created the property (active only)
class ResolvePropertyAddedTargetsUseCase {
  ResolvePropertyAddedTargetsUseCase(this._usersRepository);

  final UsersRepository _usersRepository;

  Future<List<String>> call(Property property) async {
    if (property.ownerScope == PropertyOwnerScope.company) {
      return _resolveCompanyTargets();
    }
    return _resolveBrokerTargets(property);
  }

  Future<List<String>> _resolveCompanyTargets() async {
    final owners = await _usersRepository.fetchUsers(role: UserRole.owner);
    final collectors = await _usersRepository.fetchUsers(
      role: UserRole.collector,
    );
    final brokers = await _usersRepository.fetchUsers(role: UserRole.broker);
    final ids = <String>{};
    ids.addAll(_activeIds(owners));
    ids.addAll(_activeIds(collectors));
    ids.addAll(_activeIds(brokers));
    return ids.toList();
  }

  Future<List<String>> _resolveBrokerTargets(Property property) async {
    final owners = await _usersRepository.fetchUsers(role: UserRole.owner);
    final ids = <String>{};
    ids.addAll(_activeIds(owners));
    if (property.brokerId != null && property.brokerId!.isNotEmpty) {
      final broker = await _fetchUserSafely(property.brokerId!);
      if (broker != null && broker.active && broker.role == UserRole.broker) {
        ids.add(broker.id);
      }
    }
    return ids.toList();
  }

  List<String> _activeIds(List<ManagedUser> users) =>
      users.where((u) => u.active).map((u) => u.id).toList();

  Future<ManagedUser?> _fetchUserSafely(String id) async {
    try {
      return await _usersRepository.getById(id);
    } catch (_) {
      return null;
    }
  }
}
