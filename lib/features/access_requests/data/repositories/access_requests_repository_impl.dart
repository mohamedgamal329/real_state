import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/core/pagination/page_token.dart';

import '../../../../core/constants/app_collections.dart';
import '../dtos/access_request_dto.dart';
import '../../../models/entities/access_request.dart';
import '../../../properties/domain/repositories/properties_repository.dart'
    show PageResult;
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';

class AccessRequestsRepositoryImpl implements AccessRequestsRepository {
  final FirebaseFirestore _firestore;

  AccessRequestsRepositoryImpl(this._firestore);

  /// Create an access request (status defaults to pending)
  @override
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  }) async {
    final existing = await _fetchLatest(
      propertyId: propertyId,
      requesterId: requesterId,
      type: type,
    );
    if (existing != null && existing.status == AccessRequestStatus.pending) {
      return existing;
    }
    if (targetUserId.isEmpty) {
      throw const LocalizedException('access_request_target_missing');
    }
    final now = DateTime.now();
    final expires = now.add(const Duration(hours: 24));
    final map = {
      'propertyId': propertyId,
      'requesterId': requesterId,
      'type': type.name,
      'message': message,
      'status': 'pending',
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expires),
      'ownerId': targetUserId,
    };

    final ref = await _firestore
        .collection(AppCollections.accessRequests.path)
        .add(map);
    final doc = await ref.get();
    return AccessRequestDto.fromDoc(doc);
  }

  /// Fetch a page of access requests. If [requesterId] is provided, fetch requests
  /// created by that requester (collector/broker view). If [ownerId] is provided, fetch
  /// pending requests for properties owned by that owner (owner view). Pagination
  /// is cursor-based via [startAfter].
  @override
  Future<PageResult<AccessRequest>> fetchPage({
    PageToken? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  }) async {
    Query<Map<String, dynamic>> q = _firestore.collection(
      AppCollections.accessRequests.path,
    );

    if (requesterId != null) {
      q = q.where('requesterId', isEqualTo: requesterId);
    } else if (ownerId != null) {
      q = q
          .where('ownerId', isEqualTo: ownerId)
          .where('status', isEqualTo: 'pending');
    }

    q = q.orderBy('createdAt', descending: true).limit(limit);
    final cursor = _toDocumentSnapshot(startAfter);
    if (cursor != null) q = q.startAfterDocument(cursor);

    final snap = await q.get();

    final items = snap.docs.map((d) => AccessRequestDto.fromDoc(d)).toList();

    final last = snap.docs.isNotEmpty ? snap.docs.last : null;
    final hasMore = snap.docs.length == limit;
    return PageResult(
      items: items,
      lastDocument: last != null ? PageToken(last) : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    final q = _firestore
        .collection(AppCollections.accessRequests.path)
        .where('propertyId', isEqualTo: propertyId)
        .where('requesterId', isEqualTo: requesterId)
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: AccessRequestStatus.accepted.name)
        .orderBy('decidedAt', descending: true)
        .limit(1);
    final snap = await q.get();
    if (snap.docs.isEmpty) return null;
    return AccessRequestDto.fromDoc(snap.docs.first);
  }

  @override
  Future<AccessRequest?> fetchById(String id) async {
    final doc = await _firestore
        .collection(AppCollections.accessRequests.path)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return AccessRequestDto.fromDoc(doc);
  }

  /// Update request status (accept/reject) and set decision metadata.
  @override
  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  }) async {
    final ref = _firestore
        .collection(AppCollections.accessRequests.path)
        .doc(requestId);
    final existing = await ref.get();
    if (!existing.exists) {
      throw const LocalizedException('access_request_target_missing');
    }
    final request = AccessRequestDto.fromDoc(existing);
    if (request.ownerId == null || request.ownerId!.isEmpty) {
      throw const LocalizedException('access_request_target_missing');
    }
    if (request.ownerId != decidedBy) {
      throw const LocalizedException('access_request_action_not_allowed');
    }
    final now = DateTime.now();
    await ref.update({
      'status': status.name,
      'decidedAt': Timestamp.fromDate(now),
      'decidedBy': decidedBy,
    });
    final doc = await ref.get();
    return AccessRequestDto.fromDoc(doc);
  }

  /// Watch the latest request for a given property/requester/type.
  /// Emits the latest matching AccessRequest when the underlying document changes.
  @override
  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) {
    final q = _firestore
        .collection(AppCollections.accessRequests.path)
        .where('propertyId', isEqualTo: propertyId)
        .where('requesterId', isEqualTo: requesterId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .limit(1);

    return q.snapshots().map(
      (snap) => snap.docs.isNotEmpty
          ? AccessRequestDto.fromDoc(snap.docs.first)
          : null,
    );
  }

  Future<AccessRequest?> _fetchLatest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  }) async {
    final q = _firestore
        .collection(AppCollections.accessRequests.path)
        .where('propertyId', isEqualTo: propertyId)
        .where('requesterId', isEqualTo: requesterId)
        .where('type', isEqualTo: type.name)
        .orderBy('createdAt', descending: true)
        .limit(1);
    final snap = await q.get();
    if (snap.docs.isEmpty) return null;
    return AccessRequestDto.fromDoc(snap.docs.first);
  }

  DocumentSnapshot<Map<String, dynamic>>? _toDocumentSnapshot(
    PageToken? token,
  ) {
    if (token == null) return null;
    final value = token.value;
    if (value is DocumentSnapshot<Map<String, dynamic>>) return value;
    return null;
  }
}
