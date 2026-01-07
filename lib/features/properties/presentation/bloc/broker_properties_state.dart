import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

abstract class BrokerPropertiesState extends Equatable {
  const BrokerPropertiesState();

  @override
  List<Object?> get props => [];
}

class BrokerPropertiesInitial extends BrokerPropertiesState {
  const BrokerPropertiesInitial();
}

class BrokerPropertiesLoadInProgress extends BrokerPropertiesState {
  final String brokerId;
  final PropertyFilter? filter;
  const BrokerPropertiesLoadInProgress({required this.brokerId, this.filter});

  @override
  List<Object?> get props => [brokerId, filter];
}

class BrokerPropertiesLoadSuccess extends BrokerPropertiesState {
  final String brokerId;
  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final PropertyFilter? filter;
  final Map<String, LocationArea> areaNames;

  const BrokerPropertiesLoadSuccess({
    required this.brokerId,
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
  });

  @override
  List<Object?> get props => [
    brokerId,
    items,
    lastDoc,
    hasMore,
    filter,
    areaNames,
  ];
}

class BrokerPropertiesLoadMoreInProgress extends BrokerPropertiesState {
  final String brokerId;
  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final PropertyFilter? filter;
  final Map<String, LocationArea> areaNames;

  const BrokerPropertiesLoadMoreInProgress({
    required this.brokerId,
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
  });

  @override
  List<Object?> get props => [
    brokerId,
    items,
    lastDoc,
    hasMore,
    filter,
    areaNames,
  ];
}

class BrokerPropertiesFailure extends BrokerPropertiesState {
  final String brokerId;
  final String message;
  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final PropertyFilter? filter;
  final Map<String, LocationArea> areaNames;

  const BrokerPropertiesFailure({
    required this.brokerId,
    required this.message,
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
  });

  @override
  List<Object?> get props => [
    brokerId,
    message,
    items,
    lastDoc,
    hasMore,
    filter,
    areaNames,
  ];
}
