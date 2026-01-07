import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';

abstract class BrokerAreaPropertiesState extends Equatable {
  const BrokerAreaPropertiesState();

  @override
  List<Object?> get props => [];
}

class BrokerAreaPropertiesInitial extends BrokerAreaPropertiesState {
  const BrokerAreaPropertiesInitial();
}

class BrokerAreaPropertiesLoadInProgress extends BrokerAreaPropertiesState {
  final PropertyFilter filter;
  const BrokerAreaPropertiesLoadInProgress({required this.filter});

  @override
  List<Object?> get props => [filter];
}

class BrokerAreaPropertiesLoadSuccess extends BrokerAreaPropertiesState {
  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final PropertyFilter filter;

  const BrokerAreaPropertiesLoadSuccess({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.filter,
  });

  @override
  List<Object?> get props => [items, lastDoc, hasMore, filter];
}

class BrokerAreaPropertiesLoadMoreInProgress extends BrokerAreaPropertiesState {
  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final PropertyFilter filter;

  const BrokerAreaPropertiesLoadMoreInProgress({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.filter,
  });

  @override
  List<Object?> get props => [items, lastDoc, hasMore, filter];
}

class BrokerAreaPropertiesFailure extends BrokerAreaPropertiesState {
  final String message;
  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final PropertyFilter filter;

  const BrokerAreaPropertiesFailure({
    required this.message,
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.filter,
  });

  @override
  List<Object?> get props => [message, items, lastDoc, hasMore, filter];
}
