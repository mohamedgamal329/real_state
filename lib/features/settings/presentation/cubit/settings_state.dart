part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
    this.userId,
    this.userEmail,
    this.userRole,
    this.userName,
  });

  final String? userId;
  final String? userEmail;
  final UserRole? userRole;
  final String? userName;
  final ThemeMode themeMode;

  bool get isOwner => userRole == UserRole.owner;

  @override
  List<Object?> get props => [userId, userEmail, userRole, userName, themeMode];
}

class SettingsHydrating extends SettingsState {
  const SettingsHydrating({
    required super.themeMode,
    super.userId,
    super.userEmail,
    super.userRole,
    super.userName,
  });
}

class SettingsReady extends SettingsState {
  const SettingsReady({
    required super.themeMode,
    super.userId,
    super.userEmail,
    super.userRole,
    super.userName,
  });
}

class SettingsProfileUpdating extends SettingsReady {
  const SettingsProfileUpdating({
    required super.themeMode,
    super.userId,
    super.userEmail,
    super.userRole,
    super.userName,
  });
}

class SettingsFailure extends SettingsReady {
  const SettingsFailure({
    required super.themeMode,
    super.userId,
    super.userEmail,
    super.userRole,
    super.userName,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
