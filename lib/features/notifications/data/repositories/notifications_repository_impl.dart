import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:real_state/core/constants/app_collections.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/data/dtos/app_notification_dto.dart';
import 'package:real_state/features/notifications/domain/services/notification_delivery_service.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/entities/notifications_page.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/domain/usecases/resolve_property_added_targets_usecase.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final FirebaseFirestore _firestore;
  final NotificationDeliveryService _notificationDelivery;
  final ResolvePropertyAddedTargetsUseCase _resolveTargets;

  NotificationsRepositoryImpl(
    this._firestore,
    this._notificationDelivery,
    this._resolveTargets,
  );

  @override
  Future<NotificationsPage> fetchPage({
    required String userId,
    Object? startAfter,
    int limit = 20,
  }) async {
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc;
    if (startAfter is DocumentSnapshot<Map<String, dynamic>>) {
      startAfterDoc = startAfter;
    }
    try {
      Query<Map<String, dynamic>> q = AppNotificationDto.collection(_firestore)
          .where('targetUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfterDoc != null) {
        q = q.startAfterDocument(startAfterDoc);
      }

      debugPrint(
        '[NotificationsRepository] fetchPage user=$userId limit=$limit startAfter=${startAfterDoc?.id}',
      );

      final snap = await q.get();
      final items = snap.docs.map(AppNotificationDto.fromDoc).toList();
      final last = snap.docs.isNotEmpty ? snap.docs.last : null;
      return NotificationsPage(
        items: items,
        lastDocument: last,
        hasMore: snap.docs.length == limit,
      );
    } catch (e, st) {
      debugPrint(
        '[NotificationsRepository] fetchPage failed for user=$userId: $e\n$st',
      );
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return AppNotificationDto.collection(
      _firestore,
    ).doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> sendPropertyAdded({
    required Property property,
    required String brief,
  }) async {
    final recipients = await _resolveTargets(property);
    final title = property.title?.isNotEmpty == true
        ? property.title!
        : 'property_added_title'.tr();

    for (final uid in recipients) {
      final notification = AppNotification(
        id: AppNotificationDto.collection(_firestore).doc().id,
        type: AppNotificationType.propertyAdded,
        title: title,
        body: brief,
        propertyId: property.id,
        requesterId: property.createdBy,
        targetUserId: uid,
        createdAt: DateTime.now(),
        isRead: false,
      );
      await _persistAndSend(notification);
    }
  }

  @override
  Future<void> sendAccessRequest({
    required String requestId,
    required String propertyId,
    required String targetUserId,
    required String requesterId,
    required AccessRequestType type,
    String? requesterName,
    String? message,
  }) async {
    final typeLabel = switch (type) {
      AccessRequestType.phone => 'access_request_type_phone'.tr(),
      AccessRequestType.images => 'access_request_type_images'.tr(),
      AccessRequestType.location => 'access_request_type_location'.tr(),
    };
    final notification = AppNotification(
      id: AppNotificationDto.collection(_firestore).doc().id,
      type: AppNotificationType.accessRequest,
      title: 'access_request_title'.tr(),
      body: message ?? 'access_request_body'.tr(args: [typeLabel]),
      propertyId: propertyId,
      requesterId: requesterId,
      requesterName: requesterName,
      requestId: requestId,
      requestType: type,
      requestStatus: AccessRequestStatus.pending,
      requestMessage: message,
      targetUserId: targetUserId,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _persistAndSend(notification);
  }

  @override
  Future<void> sendAccessRequestDecision({
    required AccessRequest request,
    required bool accepted,
  }) async {
    final status = accepted
        ? AccessRequestStatus.accepted
        : AccessRequestStatus.rejected;
    await _updateOwnerNotificationStatus(request.id, status);

    final notification = AppNotification(
      id: AppNotificationDto.collection(_firestore).doc().id,
      type: AppNotificationType.general,
      title: accepted
          ? 'access_request_decision_title_accepted'.tr()
          : 'access_request_decision_title_rejected'.tr(),
      body: accepted
          ? 'access_request_decision_body_accepted'.tr()
          : 'access_request_decision_body_rejected'.tr(),
      propertyId: request.propertyId,
      requesterId: request.requesterId,
      requestId: request.id,
      requestType: request.type,
      requestStatus: status,
      targetUserId: request.requesterId,
      createdAt: DateTime.now(),
      isRead: false,
    );
    await _persistAndSend(notification);
  }

  @override
  Future<void> sendGeneral({
    required String title,
    required String body,
    List<String>? userIds,
  }) async {
    final recipients = userIds ?? await _activeUserIds();
    for (final uid in recipients) {
      final notification = AppNotification(
        id: AppNotificationDto.collection(_firestore).doc().id,
        type: AppNotificationType.general,
        title: title,
        body: body,
        targetUserId: uid,
        createdAt: DateTime.now(),
        isRead: false,
      );
      await _persistAndSend(notification);
    }
  }

  Future<void> _persistAndSend(AppNotification notification) async {
    final doc = AppNotificationDto.collection(_firestore).doc(notification.id);
    await doc.set(AppNotificationDto.toMap(notification));
    final targetUserId = notification.targetUserId;
    if (targetUserId == null || targetUserId.isEmpty) return;
    try {
      final tokens = await _notificationDelivery.fetchTokensForUsers([
        targetUserId,
      ]);
      await _notificationDelivery.sendNotificationToTokens(
        tokens: tokens,
        title: notification.title,
        body: notification.body,
        notificationData: _buildDataPayload(notification),
      );
    } catch (e, st) {
      debugPrint(
        '[NotificationsRepository] Push delivery failed (notification persisted): $e\n$st',
      );
    }
  }

  Map<String, dynamic> _buildDataPayload(AppNotification notification) {
    final map = <String, String>{
      'notificationId': notification.id,
      'type': notification.type.code,
      'title': notification.title,
      'body': notification.body,
      'createdAt': notification.createdAt.toIso8601String(),
    };
    if (notification.propertyId != null)
      map['propertyId'] = notification.propertyId!;
    if (notification.requesterId != null)
      map['requesterId'] = notification.requesterId!;
    if (notification.requestId != null)
      map['requestId'] = notification.requestId!;
    if (notification.requestType != null)
      map['requestType'] = notification.requestType!.name;
    if (notification.requestStatus != null) {
      map['requestStatus'] = notification.requestStatus!.name;
    }
    if (notification.requestMessage != null) {
      map['requestMessage'] = notification.requestMessage!;
    }
    if (notification.targetUserId != null)
      map['targetUserId'] = notification.targetUserId!;
    return map;
  }

  Future<List<String>> _activeUserIds() async {
    final snap = await _firestore.collection(AppCollections.users.path).get();
    final ids = <String>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final active = (data['active'] as bool?) ?? true;
      if (active) ids.add(doc.id);
    }
    return ids;
  }

  Future<void> _updateOwnerNotificationStatus(
    String requestId,
    AccessRequestStatus status,
  ) async {
    try {
      final q = await AppNotificationDto.collection(_firestore)
          .where('requestId', isEqualTo: requestId)
          .where('type', isEqualTo: AppNotificationType.accessRequest.code)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return;
      await q.docs.first.reference.update({'requestStatus': status.name});
    } catch (e) {
      debugPrint('Failed to update owner notification status: $e');
    }
  }
}
