import '../location_areas_cache.dart';
import '../../../models/entities/location_area.dart';

class GetLocationAreasUseCase {
  final LocationAreasCache _cache;

  GetLocationAreasUseCase(LocationAreasCache cache) : _cache = cache;

  Future<List<LocationArea>> call({bool force = false}) {
    return _cache.getAll(force: force);
  }

  Future<Map<String, LocationArea>> namesByIds(List<String> ids) {
    return _cache.namesByIds(ids);
  }

  void invalidate() => _cache.invalidate();

  void prime(List<LocationArea> items) => _cache.setFromList(items);
}
