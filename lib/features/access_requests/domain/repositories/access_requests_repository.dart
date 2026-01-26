import 'dart:async';

import 'package:real_state/core/pagination/page_token.dart';

import '../../../models/entities/access_request.dart';
import '../../../properties/domain/repositories/properties_repository.dart'
    show PageResult;

/// Domain contract for working with access requests without touching Firestore.
abstract class AccessRequestsRepository {
  Future<AccessRequest> createRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
    required String targetUserId,
    String? message,
  });

  Future<AccessRequest?> fetchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  });

  Future<PageResult<AccessRequest>> fetchPage({
    PageToken? startAfter,
    int limit = 10,
    String? requesterId,
    String? ownerId,
  });

  Future<AccessRequest?> fetchLatestAcceptedRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  });

  Future<AccessRequest?> fetchById(String id);

  Future<AccessRequest> updateStatus({
    required String requestId,
    required AccessRequestStatus status,
    required String decidedBy,
  });

  Stream<AccessRequest?> watchLatestRequest({
    required String propertyId,
    required String requesterId,
    required AccessRequestType type,
  });
}
