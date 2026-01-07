part of 'manage_users_cubit.dart';

sealed class ManageUsersState extends Equatable {
  const ManageUsersState();

  @override
  List<Object?> get props => [];
}

class ManageUsersInitial extends ManageUsersState {
  const ManageUsersInitial();
}

class ManageUsersLoadInProgress extends ManageUsersState {
  const ManageUsersLoadInProgress();
}

class ManageUsersLoadSuccess extends ManageUsersState {
  const ManageUsersLoadSuccess({
    required this.collectors,
    required this.brokers,
  });

  final List<ManagedUser> collectors;
  final List<ManagedUser> brokers;

  @override
  List<Object?> get props => [collectors, brokers];
}

class ManageUsersActionInProgress extends ManageUsersLoadSuccess {
  const ManageUsersActionInProgress({
    required super.collectors,
    required super.brokers,
  });
}

class ManageUsersFailure extends ManageUsersState {
  const ManageUsersFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ManageUsersPartialFailure extends ManageUsersLoadSuccess {
  const ManageUsersPartialFailure({
    required super.collectors,
    required super.brokers,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
