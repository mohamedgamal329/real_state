enum UserRole { owner, collector, broker }

UserRole roleFromString(String? role) {
  switch (role?.toLowerCase()) {
    case 'employee':
      return UserRole.collector; // legacy employees treated as collectors
    case 'collector':
      return UserRole.collector;
    case 'broker':
      return UserRole.broker;
    case 'owner':
    default:
      return UserRole.owner;
  }
}

String roleToString(UserRole role) => role.name;
