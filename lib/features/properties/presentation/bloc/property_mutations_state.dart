import 'package:equatable/equatable.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

enum PropertyMutationType { added, updated, archived, deleted }

class PropertyMutation extends Equatable {
  const PropertyMutation({
    required this.type,
    required this.tick,
    this.propertyId,
    this.ownerScope,
    this.locationAreaId,
  });

  final PropertyMutationType type;
  final String? propertyId;
  final PropertyOwnerScope? ownerScope;
  final String? locationAreaId;
  final int tick;

  @override
  List<Object?> get props => [
    type,
    propertyId,
    ownerScope,
    locationAreaId,
    tick,
  ];
}

abstract class PropertyMutationsState extends Equatable {
  const PropertyMutationsState({this.latest});

  final PropertyMutation? latest;

  @override
  List<Object?> get props => [latest];
}

class PropertyMutationsInitial extends PropertyMutationsState {
  const PropertyMutationsInitial() : super(latest: null);
}

class PropertyMutationsActionInProgress extends PropertyMutationsState {
  const PropertyMutationsActionInProgress({PropertyMutation? previous})
    : super(latest: previous);
}

class PropertyMutationsActionSuccess extends PropertyMutationsState {
  const PropertyMutationsActionSuccess({
    required this.mutation,
    PropertyMutation? previous,
  }) : super(latest: mutation);

  final PropertyMutation mutation;

  @override
  List<Object?> get props => [mutation, latest];
}

class PropertyMutationsActionFailure extends PropertyMutationsState {
  const PropertyMutationsActionFailure({
    required this.message,
    PropertyMutation? previous,
  }) : super(latest: previous);

  final String message;

  @override
  List<Object?> get props => [message, latest];
}
