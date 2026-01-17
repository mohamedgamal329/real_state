import 'package:equatable/equatable.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

abstract class ArchivePropertiesState extends Equatable {
  const ArchivePropertiesState();

  @override
  List<Object?> get props => [];
}

class ArchivePropertiesInitial extends ArchivePropertiesState {
  const ArchivePropertiesInitial();
}

class ArchivePropertiesLoading extends ArchivePropertiesState {
  const ArchivePropertiesLoading();
}

class ArchivePropertiesLoaded extends ArchivePropertiesState {
  final List<Property> items;
  final PageToken? lastDoc;
  final bool hasMore;
  final Map<String, LocationArea> areaNames;
  final PropertyFilter filter;

  const ArchivePropertiesLoaded({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    required this.filter,
  });

  @override
  List<Object?> get props => [items, lastDoc, hasMore, areaNames, filter];
}

class ArchivePropertiesActionInProgress extends ArchivePropertiesState {
  final ArchivePropertiesLoaded previous;
  const ArchivePropertiesActionInProgress(this.previous);

  @override
  List<Object?> get props => [previous];
}

class ArchivePropertiesActionSuccess extends ArchivePropertiesState {
  final ArchivePropertiesLoaded previous;
  const ArchivePropertiesActionSuccess(this.previous);

  @override
  List<Object?> get props => [previous];
}

class ArchivePropertiesActionFailure extends ArchivePropertiesState {
  final ArchivePropertiesLoaded previous;
  final String message;
  const ArchivePropertiesActionFailure(this.previous, this.message);

  @override
  List<Object?> get props => [previous, message];
}

class ArchivePropertiesFailure extends ArchivePropertiesState {
  final String message;
  const ArchivePropertiesFailure(this.message);

  @override
  List<Object?> get props => [message];
}
