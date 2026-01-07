import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';

import '../entities/notifications_page.dart';

abstract class NotificationsRepository {
  Future<NotificationsPage> fetchPage({
    required String userId,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit,
  });

  Future<void> markAsRead(String notificationId);

  Future<void> sendPropertyAdded({required Property property, required String brief});

  Future<void> sendAccessRequest({
    required String requestId,
    required String propertyId,
    required String targetUserId,
    required String requesterId,
    required AccessRequestType type,
    String? requesterName,
    String? message,
  });

  Future<void> sendAccessRequestDecision({required AccessRequest request, required bool accepted});

  Future<void> sendGeneral({required String title, required String body, List<String>? userIds});
}
