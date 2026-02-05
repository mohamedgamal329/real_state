import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/constants/app_collections.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/location/data/dtos/sub_location_dto.dart';
import 'package:real_state/features/location/domain/repositories/sub_locations_repository.dart';
import 'package:real_state/features/models/entities/sub_location.dart';

class SubLocationsRepositoryImpl implements SubLocationsRepository {
  final FirebaseFirestore _firestore;
  final String _collection;

  SubLocationsRepositoryImpl(this._firestore, {String? collection})
    : _collection = collection ?? AppCollections.subLocations.path;

  @override
  Future<List<SubLocation>> fetchByArea(String areaId) async {
    if (areaId.isEmpty) return const [];
    try {
      final snap = await _firestore
          .collection(_collection)
          .where('areaId', isEqualTo: areaId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: false)
          .get();
      return snap.docs.map(SubLocationDto.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw LocalizedException('load_failed', args: [e.message ?? e.code]);
    } catch (e, st) {
      throw LocalizedException(
        'load_failed',
        args: [mapExceptionToFailure(e, st).toString()],
      );
    }
  }
}
