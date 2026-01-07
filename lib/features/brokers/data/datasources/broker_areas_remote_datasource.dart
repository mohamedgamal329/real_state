import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';

class BrokerAreasRemoteDataSource {
  final PropertiesRepository _propertiesRepository;
  final LocationAreaRemoteDataSource _locations;

  BrokerAreasRemoteDataSource(this._propertiesRepository, this._locations);

  Future<Set<String>> fetchBrokerAreaIds(String brokerId, {UserRole? role}) {
    return _propertiesRepository.fetchBrokerAreaIds(brokerId, role: role);
  }

  Future<PageResult<Property>> fetchBrokerPropertiesPage({
    required String brokerId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required int limit,
    UserRole? role,
  }) {
    return _propertiesRepository.fetchBrokerPage(
      brokerId: brokerId,
      startAfter: startAfter,
      limit: limit,
      role: role,
    );
  }

  Future<Map<String, String>> fetchAreaNamesByIds(List<String> ids) async {
    final names = await _locations.fetchNamesByIds(ids);
    return {
      for (final entry in names.entries) entry.key: entry.value.localizedName(),
    };
  }
}
