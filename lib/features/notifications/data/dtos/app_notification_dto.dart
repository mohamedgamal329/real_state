import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/core/constants/app_collections.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';

class AppNotificationDto {
  AppNotificationDto._();

  static CollectionReference<Map<String, dynamic>> collection(FirebaseFirestore firestore) =>
      firestore.collection(AppCollections.notifications.path);

  static AppNotification fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    AccessRequestType? requestTypeFrom(String? value) {
      switch (value) {
        case 'phone':
          return AccessRequestType.phone;
        case 'images':
          return AccessRequestType.images;
        case 'locationUrl':
        case 'location':
          return AccessRequestType.location;
        default:
          return null;
      }
    }

    AccessRequestStatus? statusFrom(String? value) {
      if (value == null) return null;
      switch (value) {
        case 'accepted':
          return AccessRequestStatus.accepted;
        case 'rejected':
          return AccessRequestStatus.rejected;
        case 'expired':
          return AccessRequestStatus.expired;
        case 'pending':
        default:
          return AccessRequestStatus.pending;
      }
    }

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return AppNotification(
      id: doc.id,
      type: AppNotificationTypeX.fromCode(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      propertyId: data['propertyId'] as String?,
      requesterId: data['requesterId'] as String?,
      requesterName: data['requesterName'] as String?,
      requestId: data['requestId'] as String?,
      requestType: requestTypeFrom(data['requestType'] as String?),
      requestStatus: statusFrom(data['requestStatus'] as String?),
      requestMessage: data['requestMessage'] as String?,
      targetUserId: data['targetUserId'] as String?,
      createdAt: createdAt,
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }

  static Map<String, Object?> toMap(AppNotification notification) {
    return {
      'type': notification.type.code,
      'title': notification.title,
      'body': notification.body,
      'propertyId': notification.propertyId,
      'requesterId': notification.requesterId,
      'requesterName': notification.requesterName,
      'requestId': notification.requestId,
      'requestType': notification.requestType?.name,
      'requestStatus': notification.requestStatus?.name,
      'requestMessage': notification.requestMessage,
      'targetUserId': notification.targetUserId,
      'createdAt': Timestamp.fromDate(notification.createdAt),
      'isRead': notification.isRead,
    };
  }
}
