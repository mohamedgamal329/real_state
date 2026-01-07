import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

sealed class PropertiesState extends Equatable {
  const PropertiesState();

  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {
  const PropertiesInitial();
}

class PropertiesLoadInProgress extends PropertiesState {
  const PropertiesLoadInProgress();
}

sealed class PropertiesDataState extends PropertiesState {
  const PropertiesDataState({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
  });

  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  final Map<String, LocationArea> areaNames;

  @override
  List<Object?> get props => [items, lastDoc, hasMore, areaNames];
}

class PropertiesLoadSuccess extends PropertiesDataState {
  const PropertiesLoadSuccess({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.areaNames,
  });
}

class PropertiesRefreshing extends PropertiesDataState {
  const PropertiesRefreshing({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.areaNames,
  });
}

class PropertiesLoadMoreInProgress extends PropertiesDataState {
  const PropertiesLoadMoreInProgress({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.areaNames,
  });
}

class PropertiesFailure extends PropertiesState {
  const PropertiesFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class PropertiesPartialFailure extends PropertiesDataState {
  const PropertiesPartialFailure({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.areaNames,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
