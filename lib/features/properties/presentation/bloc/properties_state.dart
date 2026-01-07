import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

abstract class PropertiesState extends Equatable {
  const PropertiesState();

  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {
  const PropertiesInitial();
}

class PropertiesLoading extends PropertiesState {
  const PropertiesLoading({this.filter});
  final PropertyFilter? filter;

  @override
  List<Object?> get props => [filter];
}

class PropertiesLoaded extends PropertiesState {
  const PropertiesLoaded({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
    this.infoMessage,
  });

  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final Map<String, LocationArea> areaNames;
  final PropertyFilter? filter;
  final String? infoMessage;

  @override
  List<Object?> get props => [
    items,
    lastDoc,
    hasMore,
    areaNames,
    filter,
    infoMessage,
  ];
}

class PropertiesFailure extends PropertiesState {
  const PropertiesFailure(this.message, {this.filter});
  final String message;
  final PropertyFilter? filter;

  @override
  List<Object?> get props => [message, filter];
}

class PropertiesActionInProgress extends PropertiesState {
  const PropertiesActionInProgress(this.previous);
  final PropertiesLoaded previous;

  @override
  List<Object?> get props => [previous];
}

class PropertiesActionFailure extends PropertiesState {
  const PropertiesActionFailure(this.previous, this.message);
  final PropertiesLoaded previous;
  final String message;

  @override
  List<Object?> get props => [previous, message];
}

class PropertiesActionSuccess extends PropertiesState {
  const PropertiesActionSuccess(this.previous, {this.message});
  final PropertiesLoaded previous;
  final String? message;

  @override
  List<Object?> get props => [previous, message];
}
