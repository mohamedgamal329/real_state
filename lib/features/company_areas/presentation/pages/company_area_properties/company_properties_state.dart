import 'package:equatable/equatable.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

abstract class CompanyPropertiesState extends Equatable {
  const CompanyPropertiesState();

  @override
  List<Object?> get props => [];
}

class CompanyPropertiesInitial extends CompanyPropertiesState {
  const CompanyPropertiesInitial();
}

class CompanyPropertiesLoadInProgress extends CompanyPropertiesState {
  final List<Property> items;
  final PageToken? lastDoc;
  final bool hasMore;
  final PropertyFilter? filter;
  final Map<String, LocationArea> areaNames;

  const CompanyPropertiesLoadInProgress({
    this.items = const [],
    this.lastDoc,
    this.hasMore = false,
    this.areaNames = const {},
    this.filter,
  });

  @override
  List<Object?> get props => [items, lastDoc, hasMore, filter, areaNames];
}

class CompanyPropertiesLoadSuccess extends CompanyPropertiesState {
  final List<Property> items;
  final PageToken? lastDoc;
  final bool hasMore;
  final PropertyFilter? filter;
  final Map<String, LocationArea> areaNames;

  const CompanyPropertiesLoadSuccess({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
  });

  @override
  List<Object?> get props => [items, lastDoc, hasMore, filter, areaNames];
}

class CompanyPropertiesLoadMoreInProgress extends CompanyPropertiesState {
  final List<Property> items;
  final PageToken? lastDoc;
  final bool hasMore;
  final PropertyFilter? filter;
  final Map<String, LocationArea> areaNames;

  const CompanyPropertiesLoadMoreInProgress({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
  });

  @override
  List<Object?> get props => [items, lastDoc, hasMore, filter, areaNames];
}

class CompanyPropertiesFailure extends CompanyPropertiesState {
  final String message;
  final PropertyFilter? filter;
  final List<Property> items;
  final PageToken? lastDoc;
  final bool hasMore;
  final Map<String, LocationArea> areaNames;

  const CompanyPropertiesFailure({
    required this.message,
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.areaNames,
    this.filter,
  });

  @override
  List<Object?> get props => [
    message,
    items,
    lastDoc,
    hasMore,
    filter,
    areaNames,
  ];
}
