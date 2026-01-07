import 'package:meta/meta.dart';

/// Filter parameters for property queries.
/// All fields are optional - null means no filter applied for that field.
@immutable
class PropertyFilter {
  final String? locationAreaId;
  final double? minPrice;
  final double? maxPrice;
  final int? rooms;
  final bool? hasPool;

  const PropertyFilter({
    this.locationAreaId,
    this.minPrice,
    this.maxPrice,
    this.rooms,
    this.hasPool,
    this.createdBy,
  });

  final String? createdBy;

  /// Returns true if no filters are set
  bool get isEmpty =>
      locationAreaId == null &&
      minPrice == null &&
      maxPrice == null &&
      rooms == null &&
      hasPool == null &&
      createdBy == null;

  PropertyFilter copyWith({
    String? locationAreaId,
    double? minPrice,
    double? maxPrice,
    int? rooms,
    bool? hasPool,
    String? createdBy,
    bool clearLocationAreaId = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearRooms = false,
    bool clearHasPool = false,
    bool clearCreatedBy = false,
  }) {
    return PropertyFilter(
      locationAreaId: clearLocationAreaId ? null : (locationAreaId ?? this.locationAreaId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      rooms: clearRooms ? null : (rooms ?? this.rooms),
      hasPool: clearHasPool ? null : (hasPool ?? this.hasPool),
      createdBy: clearCreatedBy ? null : (createdBy ?? this.createdBy),
    );
  }

  /// Clear all filters
  static const PropertyFilter empty = PropertyFilter();
}
