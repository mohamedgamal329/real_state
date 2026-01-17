import 'package:equatable/equatable.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

abstract class CategoriesCoreState extends CategoriesState {
  const CategoriesCoreState({
    required this.filter,
    required this.locationAreas,
    required this.areaNames,
  });

  final PropertyFilter filter;
  final List<LocationArea> locationAreas;
  final Map<String, LocationArea> areaNames;

  @override
  List<Object?> get props => [filter, locationAreas, areaNames];
}

abstract class CategoriesListState extends CategoriesCoreState {
  const CategoriesListState({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<Property> items;
  final PageToken? lastDoc;
  final bool hasMore;

  @override
  List<Object?> get props => [...super.props, items, lastDoc, hasMore];
}

class CategoriesInitial extends CategoriesCoreState {
  const CategoriesInitial({
    PropertyFilter filter = const PropertyFilter(),
    List<LocationArea> locationAreas = const [],
    Map<String, LocationArea> areaNames = const {},
  }) : super(
         filter: filter,
         locationAreas: locationAreas,
         areaNames: areaNames,
       );
}

class CategoriesLoadInProgress extends CategoriesCoreState {
  const CategoriesLoadInProgress({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
  });
}

class CategoriesLoadSuccess extends CategoriesListState {
  const CategoriesLoadSuccess({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
    required super.items,
    required super.lastDoc,
    required super.hasMore,
  });
}

class CategoriesRefreshing extends CategoriesListState {
  const CategoriesRefreshing({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
    required super.items,
    required super.lastDoc,
    required super.hasMore,
  });
}

class CategoriesLoadMoreInProgress extends CategoriesListState {
  const CategoriesLoadMoreInProgress({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
    required super.items,
    required super.lastDoc,
    required super.hasMore,
  });
}

class CategoriesFailure extends CategoriesCoreState {
  const CategoriesFailure({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}

class CategoriesPartialFailure extends CategoriesListState {
  const CategoriesPartialFailure({
    required super.filter,
    required super.locationAreas,
    required super.areaNames,
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}
