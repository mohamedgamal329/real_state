import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';

import '../../../../core/constants/app_collections.dart';
import '../../../models/dtos/location_area_dto.dart';
import '../../../models/entities/location_area.dart';

class LocationAreaRemoteDataSource {
  final FirebaseFirestore _firestore;
  final String _collection;

  LocationAreaRemoteDataSource(this._firestore, {String? collection})
    : _collection = collection ?? AppCollections.locationAreas.path;

  Future<Map<String, LocationArea>> fetchNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    try {
      final col = _firestore.collection(_collection);
      final snaps = await Future.wait(ids.map((id) => col.doc(id).get()));
      final map = <String, LocationArea>{};
      for (final s in snaps) {
        if (s.exists) {
          map[s.id] = LocationAreaDto.fromDoc(s);
        }
      }
      return map;
    } catch (e, st) {
      debugPrint('fetchNamesByIds failed: ${mapErrorMessage(e, stackTrace: st)}');
      return {};
    }
  }

  /// Fetch all location areas for filter dropdown.
  Future<Map<String, LocationArea>> fetchAll() async {
    try {
      final snap = await _firestore.collection(_collection).get();
      final map = <String, LocationArea>{};
      for (final doc in snap.docs) {
        map[doc.id] = LocationAreaDto.fromDoc(doc);
      }
      return map;
    } catch (e, st) {
      debugPrint('fetchAllLocationAreas failed: ${mapErrorMessage(e, stackTrace: st)}');
      return {};
    }
  }
}
