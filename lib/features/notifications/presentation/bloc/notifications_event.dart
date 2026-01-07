import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsStarted extends NotificationsEvent {
  const NotificationsStarted();
}

class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

class NotificationsLoadMoreRequested extends NotificationsEvent {
  const NotificationsLoadMoreRequested();
}

class NotificationsMarkReadRequested extends NotificationsEvent {
  final String notificationId;
  const NotificationsMarkReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class NotificationsAcceptRequested extends NotificationsEvent {
  final String notificationId;
  final String requestId;
  final Completer<String?>? completer;
  const NotificationsAcceptRequested(
    this.notificationId,
    this.requestId, {
    this.completer,
  });

  @override
  List<Object?> get props => [notificationId, requestId];
}

class NotificationsRejectRequested extends NotificationsEvent {
  final String notificationId;
  final String requestId;
  final Completer<String?>? completer;
  const NotificationsRejectRequested(
    this.notificationId,
    this.requestId, {
    this.completer,
  });

  @override
  List<Object?> get props => [notificationId, requestId];
}

class NotificationsIncomingPushed extends NotificationsEvent {
  final String currentUserId;
  final AppNotification notification;
  const NotificationsIncomingPushed(this.notification, this.currentUserId);

  @override
  List<Object?> get props => [notification, currentUserId];
}

class NotificationsClearInfoRequested extends NotificationsEvent {
  const NotificationsClearInfoRequested();
}
