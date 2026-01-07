import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/errors/localized_exception.dart';

import '../../../models/entities/location_area.dart';
import '../../../properties/data/datasources/location_area_remote_datasource.dart';
import '../../../properties/data/repositories/properties_repository.dart';
import '../../domain/entities/company_area_summary.dart';
import '../../domain/repositories/company_areas_repository.dart';

class CompanyAreasRepositoryImpl implements CompanyAreasRepository {
  final PropertiesRepository _propertiesRepository;
  final LocationAreaRemoteDataSource _locations;

  CompanyAreasRepositoryImpl(this._propertiesRepository, this._locations);

  @override
  Future<List<AreaSummary>> fetchCompanyAreas() async {
    final counts = <String, int>{};
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    var hasMore = true;
    try {
      while (hasMore) {
        final page = await _propertiesRepository.fetchCompanyPage(startAfter: cursor, limit: 50);
        for (final property in page.items) {
          final areaId = property.locationAreaId ?? '';
          counts[areaId] = (counts[areaId] ?? 0) + 1;
        }
        cursor = page.lastDocument;
        hasMore = page.hasMore;
      }
    } catch (e) {
      if (e is LocalizedException) rethrow;
      throw LocalizedException('load_failed', args: [e.toString()]);
    }

    final ids = counts.keys.where((id) => id.isNotEmpty).toList();
    Map<String, LocationArea> names = {};
    if (ids.isNotEmpty) {
      try {
        names = await _locations.fetchNamesByIds(ids);
      } catch (_) {
        names = {};
      }
    }

    final areas =
        counts.entries
            .map(
              (entry) => AreaSummary(
                areaId: entry.key,
                name: names[entry.key]?.localizedName() ?? (entry.key.isEmpty ? '' : entry.key),
                count: entry.value,
                imageUrl: names[entry.key]?.imageUrl ?? '',
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return areas;
  }
}
