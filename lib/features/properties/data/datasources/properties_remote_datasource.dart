import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_collections.dart';
import '../dtos/property_dto.dart';
import '../../../models/entities/property.dart';

class PropertiesRemoteDataSource {
  final FirebaseFirestore _firestore;
  final String _collection;

  PropertiesRemoteDataSource(this._firestore, {String? collection})
    : _collection = collection ?? AppCollections.properties.path;

  /// Fetch a page of properties ordered by createdAt desc.
  Future<List<Property>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    var q = _firestore
        .collection(_collection)
        .where('isDeleted', isEqualTo: false)
        .where('status', isEqualTo: PropertyStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) q = q.startAfterDocument(startAfter);

    final snap = await q.get();
    return snap.docs.map((d) => PropertyDto.fromDoc(d)).toList();
  }

  /// Fetch a document snapshot for pagination cursor.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getLastDocument(
    List<Property> items,
  ) async {
    // This is simplified: caller should keep track of last document by re-querying with same query.
    // For precise cursors, we can return the last fetched document snapshots by performing the same query and grabbing docs.
    return null;
  }
}
