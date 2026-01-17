import 'package:equatable/equatable.dart';
import 'package:real_state/features/properties/domain/models/property_mutation.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

abstract class PropertyMutationsEvent extends Equatable {
  const PropertyMutationsEvent();

  @override
  List<Object?> get props => [];
}

class PropertyMutationStarted extends PropertyMutationsEvent {
  const PropertyMutationStarted({
    required this.type,
    this.propertyId,
    this.ownerScope,
    this.locationAreaId,
  });

  final PropertyMutationType type;
  final String? propertyId;
  final PropertyOwnerScope? ownerScope;
  final String? locationAreaId;

  @override
  List<Object?> get props => [type, propertyId, ownerScope, locationAreaId];
}

class PropertyMutationFailed extends PropertyMutationsEvent {
  const PropertyMutationFailed(this.error, {this.previous});

  final Object error;
  final PropertyMutation? previous;

  @override
  List<Object?> get props => [error, previous];
}

class PropertyMutationReset extends PropertyMutationsEvent {
  const PropertyMutationReset();
}
