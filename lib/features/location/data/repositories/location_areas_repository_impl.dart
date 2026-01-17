import '../../../models/entities/location_area.dart';
import '../../domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';

class LocationAreasRepositoryImpl implements LocationAreasRepository {
  LocationAreasRepositoryImpl(this._remote);

  final LocationAreaRemoteDataSource _remote;
  final Map<String, LocationArea> _cache = {};

  @override
  Future<Map<String, LocationArea>> fetchAll() async {
    final result = await _remote.fetchAll();
    _cache.addAll(result);
    return result;
  }

  @override
  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final missing = ids.where((id) => !_cache.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      final fetched = await _remote.fetchNamesByIds(missing);
      _cache.addAll(fetched);
    }
    final result = <String, LocationArea>{};
    for (final id in ids) {
      final cached = _cache[id];
      if (cached != null) {
        result[id] = cached;
      }
    }
    return result;
  }
}
