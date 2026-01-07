import 'package:meta/meta.dart';
import 'package:real_state/features/models/entities/access_request.dart';

@immutable
class AppNotification {
  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final String? propertyId;
  final String? requesterId;
  final String? requesterName;
  final String? requestId;
  final AccessRequestType? requestType;
  final AccessRequestStatus? requestStatus;
  final String? requestMessage;
  final String? targetUserId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.propertyId,
    this.requesterId,
    this.requestId,
    this.requestType,
    this.requestStatus,
    this.requestMessage,
    this.requesterName,
    this.targetUserId,
  });

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    String? title,
    String? body,
    String? propertyId,
    String? requesterId,
    String? requesterName,
    String? requestId,
    AccessRequestType? requestType,
    AccessRequestStatus? requestStatus,
    String? requestMessage,
    String? targetUserId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      propertyId: propertyId ?? this.propertyId,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requestId: requestId ?? this.requestId,
      requestType: requestType ?? this.requestType,
      requestStatus: requestStatus ?? this.requestStatus,
      requestMessage: requestMessage ?? this.requestMessage,
      targetUserId: targetUserId ?? this.targetUserId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

enum AppNotificationType { propertyAdded, accessRequest, general }

extension AppNotificationTypeX on AppNotificationType {
  String get code {
    switch (this) {
      case AppNotificationType.propertyAdded:
        return 'property_added';
      case AppNotificationType.accessRequest:
        return 'access_request';
      case AppNotificationType.general:
        return 'general';
    }
  }

  static AppNotificationType fromCode(String? code) {
    switch (code) {
      case 'property_added':
        return AppNotificationType.propertyAdded;
      case 'access_request':
        return AppNotificationType.accessRequest;
      case 'general':
      default:
        return AppNotificationType.general;
    }
  }
}
