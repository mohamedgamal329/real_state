import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/constants/app_collections.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/properties/data/dtos/property_dto.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';

import '../../domain/property_permissions.dart';

class PropertiesRepositoryImpl implements PropertiesRepository {
  final FirebaseFirestore _firestore;
  final String _collection;

  PropertiesRepositoryImpl(this._firestore, {String? collection})
    : _collection = collection ?? AppCollections.properties.path;

  @override
  String generateId() => _firestore.collection(_collection).doc().id;

  @override
  Future<PageResult<Property>> fetchCompanyPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) {
    return _fetchScopedPage(
      scope: PropertyOwnerScope.company,
      brokerId: null,
      startAfter: startAfter,
      limit: limit,
      filter: filter,
    );
  }

  @override
  Future<PageResult<Property>> fetchBrokerPage({
    required String brokerId,
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
    UserRole? role,
  }) {
    if (role == UserRole.collector) {
      throw const LocalizedException('access_denied_broker_data');
    }
    return _fetchScopedPage(
      scope: PropertyOwnerScope.broker,
      brokerId: brokerId,
      startAfter: startAfter,
      limit: limit,
      filter: filter,
    );
  }

  @override
  Future<Set<String>> fetchBrokerAreaIds(
    String brokerId, {
    UserRole? role,
  }) async {
    if (role == UserRole.collector) {
      throw const LocalizedException('access_denied_broker_data');
    }
    try {
      final snap = await _collectionRoot()
          .where('ownerScope', isEqualTo: PropertyOwnerScope.broker.name)
          .where('brokerId', isEqualTo: brokerId)
          .where('isDeleted', isEqualTo: false)
          .get();
      final ids = <String>{};
      for (final doc in snap.docs) {
        final areaId = (doc.data()['locationAreaId'] as String?);
        if (areaId != null && areaId.isNotEmpty) ids.add(areaId);
      }
      return ids;
    } catch (e) {
      throw LocalizedException(
        'load_failed',
        args: [mapExceptionToFailure(e).toString()],
      );
    }
  }

  Future<PageResult<Property>> _fetchScopedPage({
    required PropertyOwnerScope scope,
    required String? brokerId,
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) async {
    final hasPriceInequality =
        (filter?.minPrice != null) || (filter?.maxPrice != null);
    final baseQuery = hasPriceInequality
        ? _buildPriceQuery(filter, scope: scope, brokerId: brokerId)
        : _buildBaseQuery(filter, scope: scope, brokerId: brokerId);
    final chunk = limit * 3;
    final List<Property> results = [];
    var cursor = _toDocumentSnapshot(startAfter);
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    var moreServer = true;
    try {
      while (results.length < limit && moreServer) {
        final snap = await _applyPagination(
          baseQuery,
          limit: chunk,
          startAfter: cursor,
        ).get();
        if (snap.docs.isEmpty) {
          moreServer = false;
          break;
        }
        lastDoc = snap.docs.last;
        cursor = lastDoc;
        for (final doc in snap.docs) {
          final property = PropertyDto.fromDoc(doc);
          if (_matchesClientFilter(property, filter)) {
            results.add(property);
            if (results.length == limit) break;
          }
        }
        if (snap.docs.length < chunk) {
          moreServer = false;
        }
      }
      return PageResult(
        items: results,
        lastDocument: lastDoc != null ? PageToken(lastDoc) : null,
        hasMore: moreServer && results.isNotEmpty,
      );
    } on FirebaseException catch (e) {
      throw LocalizedException('load_failed', args: [e.message ?? e.code]);
    }
  }

  @override
  Future<PageResult<Property>> fetchPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) async {
    // Keep Firestore filters minimal to avoid composite index prompts; most
    // filters (status, deletion, rooms, pool, location) are applied client-side.
    final hasPriceInequality =
        (filter?.minPrice != null) || (filter?.maxPrice != null);
    final baseQuery = hasPriceInequality
        ? _buildPriceQuery(filter)
        : _buildBaseQuery(filter);
    final chunk =
        limit *
        3; // fetch more per round to compensate for client-side filtering
    final List<Property> results = [];
    var cursor = _toDocumentSnapshot(startAfter);
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    var moreServer = true;
    try {
      while (results.length < limit && moreServer) {
        final snap = await _applyPagination(
          baseQuery,
          limit: chunk,
          startAfter: cursor,
        ).get();
        if (snap.docs.isEmpty) {
          moreServer = false;
          break;
        }

        lastDoc = snap.docs.last;
        cursor = lastDoc;

        for (final doc in snap.docs) {
          final property = PropertyDto.fromDoc(doc);
          if (_matchesClientFilter(property, filter)) {
            results.add(property);
            if (results.length == limit) break;
          }
        }

        // If Firestore returned fewer docs than requested, we've reached the end.
        // Otherwise continue fetching until we satisfy limit or exhaust data.
        if (snap.docs.length < chunk) {
          moreServer = false;
        }
      }

      return PageResult(
        items: results,
        lastDocument: lastDoc != null ? PageToken(lastDoc) : null,
        hasMore: moreServer && results.isNotEmpty,
      );
    } on FirebaseException catch (e) {
      // Surface a clearer error for index/inequality issues so QA/devs can act.
      // Common messages: requires an index, or invalid query (inequality + orderBy mismatch)
      throw LocalizedException('load_failed', args: [e.message ?? e.code]);
    }
  }

  @override
  Future<PageResult<Property>> fetchArchivedPage({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) async {
    final baseQuery = _buildBaseQuery(null);
    final chunk = limit * 3;
    final List<Property> results = [];
    var cursor = _toDocumentSnapshot(startAfter);
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    var moreServer = true;
    try {
      while (results.length < limit && moreServer) {
        final snap = await _applyPagination(
          baseQuery,
          limit: chunk,
          startAfter: cursor,
        ).get();
        if (snap.docs.isEmpty) {
          moreServer = false;
          break;
        }

        lastDoc = snap.docs.last;
        cursor = lastDoc;

        for (final doc in snap.docs) {
          final property = PropertyDto.fromDoc(doc);
          if (_matchesArchivedFilter(property, filter)) {
            results.add(property);
            if (results.length == limit) break;
          }
        }

        if (snap.docs.length < chunk) {
          moreServer = false;
        }
      }

      return PageResult(
        items: results,
        lastDocument: lastDoc != null ? PageToken(lastDoc) : null,
        hasMore: moreServer && results.isNotEmpty,
      );
    } on FirebaseException catch (e) {
      throw LocalizedException('load_failed', args: [e.message ?? e.code]);
    }
  }

  Query<Map<String, dynamic>> _buildBaseQuery(
    PropertyFilter? filter, {
    PropertyOwnerScope? scope,
    String? brokerId,
  }) {
    var q = _collectionRoot();
    if (scope != null) {
      q = q.where('ownerScope', isEqualTo: scope.name);
      if (scope == PropertyOwnerScope.broker && brokerId != null) {
        q = q.where('brokerId', isEqualTo: brokerId);
      }
      q = q.where('isDeleted', isEqualTo: false);
    }
    return q.orderBy('createdAt', descending: true);
  }

  /// Price inequality path is split to a dedicated shape to comply with Firestore
  /// requirements (orderBy starts with the inequality field) and to avoid
  /// explosive composite indexes.
  Query<Map<String, dynamic>> _buildPriceQuery(
    PropertyFilter? filter, {
    PropertyOwnerScope? scope,
    String? brokerId,
  }) {
    var q = _collectionRoot();
    if (scope != null) {
      q = q.where('ownerScope', isEqualTo: scope.name);
      if (scope == PropertyOwnerScope.broker && brokerId != null) {
        q = q.where('brokerId', isEqualTo: brokerId);
      }
      q = q.where('isDeleted', isEqualTo: false);
    }

    if (filter?.minPrice != null) {
      q = q.where('price', isGreaterThanOrEqualTo: filter!.minPrice);
    }
    if (filter?.maxPrice != null) {
      q = q.where('price', isLessThanOrEqualTo: filter!.maxPrice);
    }

    // Order by price only; createdAt is filtered client-side to avoid composite index.
    return q.orderBy('price');
  }

  Query<Map<String, dynamic>> _applyPagination(
    Query<Map<String, dynamic>> q, {
    required int limit,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    q = q.limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q;
  }

  DocumentSnapshot<Map<String, dynamic>>? _toDocumentSnapshot(
    PageToken? token,
  ) {
    if (token == null) return null;
    final value = token.value;
    if (value is DocumentSnapshot<Map<String, dynamic>>) return value;
    return null;
  }

  Query<Map<String, dynamic>> _collectionRoot() =>
      _firestore.collection(_collection);

  bool _matchesClientFilter(Property property, PropertyFilter? filter) {
    if (property.isDeleted || property.status != PropertyStatus.active)
      return false;
    if (filter?.locationAreaId != null &&
        property.locationAreaId != filter!.locationAreaId) {
      return false;
    }
    if (filter == null) return true;
    if (filter.rooms != null && property.rooms != filter.rooms) return false;
    if (filter.hasPool == true && property.hasPool != true) return false;
    if (filter.createdBy != null && property.createdBy != filter.createdBy) {
      return false;
    }
    return true;
  }

  bool _matchesArchivedFilter(Property property, PropertyFilter? filter) {
    if (property.isDeleted) return false;
    if (property.status != PropertyStatus.archived) return false;
    if (filter == null) return true;
    if (filter.locationAreaId != null &&
        property.locationAreaId != filter.locationAreaId) {
      return false;
    }
    if (filter.rooms != null && property.rooms != filter.rooms) return false;
    if (filter.hasPool == true && property.hasPool != true) return false;
    if (filter.createdBy != null && property.createdBy != filter.createdBy) {
      return false;
    }
    if (filter.minPrice != null) {
      final price = property.price;
      if (price == null || price < filter.minPrice!) return false;
    }
    if (filter.maxPrice != null) {
      final price = property.price;
      if (price == null || price > filter.maxPrice!) return false;
    }
    return true;
  }

  /// Fetch a single property by id
  @override
  Future<Property?> getById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return PropertyDto.fromDoc(doc);
  }

  /// Fetch multiple properties by ids in chunks using whereIn (10 max per query).
  @override
  Future<Map<String, Property?>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final results = <String, Property?>{};
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10));
    }
    for (final chunk in chunks) {
      try {
        final snap = await _firestore
            .collection(_collection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          results[doc.id] = PropertyDto.fromDoc(doc);
        }
      } on FirebaseException catch (e) {
        throw LocalizedException('load_failed', args: [e.message ?? e.code]);
      }
      // Mark missing ids explicitly as null to avoid refetch loops.
      for (final id in chunk) {
        results.putIfAbsent(id, () => null);
      }
    }
    return results;
  }

  /// Create a property document. Only owners/collectors/brokers may create.
  /// Assignment defaults to "all" as per requirements.
  @override
  Future<Property> createProperty({
    String? id,
    required String userId,
    required UserRole userRole,
    String? title,
    String? description,
    PropertyPurpose purpose = PropertyPurpose.sale,
    int? rooms,
    int? kitchens,
    int? floors,
    bool hasPool = false,
    String? locationAreaId,
    String? locationUrl,
    double? price,
    String? ownerPhoneEncryptedOrHiddenStored,
    String? securityGuardPhoneEncryptedOrHiddenStored,
    String? securityNumberEncryptedOrHiddenStored,
    bool isImagesHidden = false,
    List<String> imageUrls = const [],
    String? coverImageUrl,
  }) async {
    if (!canCreateProperty(userRole)) {
      throw const LocalizedException('access_denied_add');
    }
    final now = DateTime.now();
    final docRef = _firestore.collection(_collection).doc(id ?? generateId());
    final ownerScope = resolveOwnerScopeByRole(userRole);
    final brokerId = ownerScope == PropertyOwnerScope.broker ? userId : null;
    final prop = Property(
      id: docRef.id,
      title: title,
      description: description,
      price: price,
      purpose: purpose,
      rooms: rooms,
      kitchens: kitchens,
      floors: floors,
      hasPool: hasPool,
      locationAreaId: locationAreaId,
      locationUrl: locationUrl,
      coverImageUrl: coverImageUrl,
      imageUrls: imageUrls,
      ownerPhoneEncryptedOrHiddenStored: ownerPhoneEncryptedOrHiddenStored,
      securityGuardPhoneEncryptedOrHiddenStored:
          securityGuardPhoneEncryptedOrHiddenStored,
      securityNumberEncryptedOrHiddenStored:
          securityNumberEncryptedOrHiddenStored,
      isImagesHidden: isImagesHidden,
      status: PropertyStatus.active,
      isDeleted: false,
      createdBy: userId,
      ownerScope: ownerScope,
      brokerId: brokerId,
      createdAt: now,
      updatedAt: now,
      updatedBy: userId,
    );
    await docRef.set(PropertyDto.toMap(prop));
    final saved = await docRef.get();
    return PropertyDto.fromDoc(saved);
  }

  /// Update an existing property with permission checks.
  @override
  Future<Property> updateProperty({
    required String id,
    required String userId,
    required UserRole userRole,
    String? title,
    String? description,
    PropertyPurpose? purpose,
    int? rooms,
    int? kitchens,
    int? floors,
    bool? hasPool,
    String? locationAreaId,
    String? locationUrl,
    double? price,
    String? ownerPhoneEncryptedOrHiddenStored,
    String? securityGuardPhoneEncryptedOrHiddenStored,
    String? securityNumberEncryptedOrHiddenStored,
    bool? isImagesHidden,
    List<String>? imageUrls,
    String? coverImageUrl,
    PropertyStatus? status,
  }) async {
    final ref = _firestore.collection(_collection).doc(id);
    final doc = await ref.get();
    if (!doc.exists) {
      throw const LocalizedException('property_not_found');
    }
    final existing = PropertyDto.fromDoc(doc);
    if (!canModifyProperty(
      property: existing,
      userId: userId,
      role: userRole,
    )) {
      throw const LocalizedException('access_denied_edit');
    }

    final updateMap = <String, Object?>{};
    if (title != null) updateMap['title'] = title;
    if (description != null) updateMap['description'] = description;
    if (purpose != null) updateMap['purpose'] = purpose.name;
    if (rooms != null) updateMap['rooms'] = rooms;
    if (kitchens != null) updateMap['kitchens'] = kitchens;
    if (floors != null) updateMap['floors'] = floors;
    if (hasPool != null) updateMap['hasPool'] = hasPool;
    if (locationAreaId != null) updateMap['locationAreaId'] = locationAreaId;
    if (locationUrl != null) updateMap['locationUrl'] = locationUrl;
    if (price != null) updateMap['price'] = price;
    if (ownerPhoneEncryptedOrHiddenStored != null) {
      updateMap['ownerPhoneEncryptedOrHiddenStored'] =
          ownerPhoneEncryptedOrHiddenStored;
    }
    if (securityGuardPhoneEncryptedOrHiddenStored != null) {
      updateMap['securityGuardPhoneEncryptedOrHiddenStored'] =
          securityGuardPhoneEncryptedOrHiddenStored;
    }
    if (securityNumberEncryptedOrHiddenStored != null) {
      updateMap['securityNumberEncryptedOrHiddenStored'] =
          securityNumberEncryptedOrHiddenStored;
    }
    if (isImagesHidden != null) updateMap['isImagesHidden'] = isImagesHidden;
    if (imageUrls != null) updateMap['imageUrls'] = imageUrls;
    if (coverImageUrl != null) updateMap['coverImageUrl'] = coverImageUrl;
    if (status != null) updateMap['status'] = status.name;

    updateMap['updatedAt'] = Timestamp.fromDate(DateTime.now());
    updateMap['updatedBy'] = userId;

    await ref.update(updateMap);
    final updated = await ref.get();
    return PropertyDto.fromDoc(updated);
  }

  @override
  Future<Property> archiveProperty({
    required String id,
    required String userId,
    required UserRole userRole,
  }) {
    return _archiveWithPermission(id: id, userId: userId, userRole: userRole);
  }

  Future<Property> _archiveWithPermission({
    required String id,
    required String userId,
    required UserRole userRole,
  }) async {
    final existing = await getById(id);
    if (existing != null &&
        !canArchiveOrDeleteProperty(
          property: existing,
          userId: userId,
          role: userRole,
        )) {
      throw const LocalizedException('access_denied_delete');
    }
    return updateProperty(
      id: id,
      userId: userId,
      userRole: userRole,
      status: PropertyStatus.archived,
    );
  }

  @override
  Future<void> deleteProperty({
    required String id,
    required String userId,
    required UserRole userRole,
  }) async {
    final ref = _firestore.collection(_collection).doc(id);
    final doc = await ref.get();
    if (!doc.exists) return;
    final existing = PropertyDto.fromDoc(doc);
    if (!canArchiveOrDeleteProperty(
      property: existing,
      userId: userId,
      role: userRole,
    )) {
      throw const LocalizedException('access_denied_delete');
    }
    await ref.update({
      'isDeleted': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'updatedBy': userId,
    });
  }
}
