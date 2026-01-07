part of 'manage_locations_cubit.dart';

sealed class ManageLocationsState extends Equatable {
  const ManageLocationsState();

  @override
  List<Object?> get props => [];
}

class ManageLocationsCheckingAccess extends ManageLocationsState {
  const ManageLocationsCheckingAccess();
}

class ManageLocationsAccessDenied extends ManageLocationsState {
  const ManageLocationsAccessDenied({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class ManageLocationsLoadInProgress extends ManageLocationsState {
  const ManageLocationsLoadInProgress();
}

sealed class ManageLocationsDataState extends ManageLocationsState {
  const ManageLocationsDataState(this.items);
  final List<LocationArea> items;

  @override
  List<Object?> get props => [items];
}

class ManageLocationsLoadSuccess extends ManageLocationsDataState {
  const ManageLocationsLoadSuccess({required List<LocationArea> items})
    : super(items);
}

class ManageLocationsActionInProgress extends ManageLocationsDataState {
  const ManageLocationsActionInProgress({required List<LocationArea> items})
    : super(items);
}

class ManageLocationsFailure extends ManageLocationsState {
  const ManageLocationsFailure({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class ManageLocationsPartialFailure extends ManageLocationsDataState {
  const ManageLocationsPartialFailure({
    required List<LocationArea> items,
    required this.message,
  }) : super(items);
  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
