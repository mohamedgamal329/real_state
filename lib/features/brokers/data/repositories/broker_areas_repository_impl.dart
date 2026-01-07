import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/brokers/data/datasources/broker_areas_remote_datasource.dart';
import 'package:real_state/features/brokers/domain/entities/broker_area.dart';
import 'package:real_state/features/brokers/domain/repositories/broker_areas_repository.dart';

class BrokerAreasRepositoryImpl implements BrokerAreasRepository {
  final BrokerAreasRemoteDataSource _remote;
  final int _pageSize;

  BrokerAreasRepositoryImpl(this._remote, {int pageSize = 50}) : _pageSize = pageSize;

  @override
  Future<List<BrokerArea>> fetchBrokerAreas(
    String brokerId, {
    UserRole? role,
    Map<String, String> cachedAreaNames = const {},
  }) async {
    final areaIds = await _remote.fetchBrokerAreaIds(brokerId, role: role);
    if (areaIds.isEmpty) return const [];

    final names = {...cachedAreaNames};
    final missing = areaIds.where((id) => !names.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      try {
        names.addAll(await _remote.fetchAreaNamesByIds(missing));
      } catch (_) {
        // Keep existing data even if name lookup fails.
      }
    }

    final counts = await _countPropertiesByArea(
      brokerId: brokerId,
      areaIds: areaIds.toSet(),
      role: role,
    );

    final areas =
        areaIds
            .map(
              (id) =>
                  BrokerArea(id: id, name: _resolveName(id, names), propertyCount: counts[id] ?? 0),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return areas;
  }

  Future<Map<String, int>> _countPropertiesByArea({
    required String brokerId,
    required Set<String> areaIds,
    UserRole? role,
  }) async {
    final counts = {for (final id in areaIds) id: 0};
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    var hasMore = true;

    while (hasMore) {
      final page = await _remote.fetchBrokerPropertiesPage(
        brokerId: brokerId,
        startAfter: cursor,
        limit: _pageSize,
        role: role,
      );

      for (final property in page.items) {
        final areaId = property.locationAreaId;
        if (areaId == null || areaId.isEmpty || !areaIds.contains(areaId)) continue;
        counts[areaId] = (counts[areaId] ?? 0) + 1;
      }

      cursor = page.lastDocument;
      hasMore = page.hasMore;
      if (!hasMore) break;
    }

    return counts;
  }

  String _resolveName(String id, Map<String, String> names) {
    final name = names[id]?.trim() ?? '';
    if (name.isEmpty) return id;
    return name;
  }
}
