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
