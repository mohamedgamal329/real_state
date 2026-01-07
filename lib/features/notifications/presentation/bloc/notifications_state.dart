import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/presentation/models/notification_property_summary.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

mixin NotificationsStateWithRole on NotificationsState {
  bool get isOwner;
  bool get isCollector;
}

class NotificationsInitial extends NotificationsState
    with NotificationsStateWithRole {
  const NotificationsInitial({this.isOwner = false, this.isCollector = false});
  @override
  final bool isOwner;
  @override
  final bool isCollector;

  @override
  List<Object?> get props => [isOwner, isCollector];
}

class NotificationsLoading extends NotificationsState
    with NotificationsStateWithRole {
  const NotificationsLoading({
    required this.isOwner,
    required this.isCollector,
  });
  @override
  final bool isOwner;
  @override
  final bool isCollector;

  @override
  List<Object?> get props => [isOwner, isCollector];
}

abstract class NotificationsDataState extends NotificationsState
    with NotificationsStateWithRole {
  const NotificationsDataState({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
    required this.isOwner,
    required this.isCollector,
    required this.propertySummaries,
    required this.pendingRequestIds,
    this.infoMessage,
  });

  final List<AppNotification> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
  @override
  final bool isOwner;
  @override
  final bool isCollector;
  final Map<String, NotificationPropertySummary> propertySummaries;
  final Set<String> pendingRequestIds;
  final String? infoMessage;

  @override
  List<Object?> get props => [
    items,
    lastDoc,
    hasMore,
    isOwner,
    isCollector,
    propertySummaries,
    pendingRequestIds,
    infoMessage,
  ];
}

class NotificationsLoaded extends NotificationsDataState {
  const NotificationsLoaded({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.isOwner,
    required super.isCollector,
    required super.propertySummaries,
    required super.pendingRequestIds,
    super.infoMessage,
  });
}

class NotificationsFailure extends NotificationsState
    with NotificationsStateWithRole {
  const NotificationsFailure({
    required this.message,
    required this.isOwner,
    required this.isCollector,
  });
  final String message;
  @override
  final bool isOwner;
  @override
  final bool isCollector;

  @override
  List<Object?> get props => [message, isOwner, isCollector];
}

class NotificationsPartialFailure extends NotificationsDataState {
  const NotificationsPartialFailure({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.isOwner,
    required super.isCollector,
    required super.propertySummaries,
    required super.pendingRequestIds,
    required this.message,
    super.infoMessage,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}

class NotificationsActionInProgress extends NotificationsDataState {
  const NotificationsActionInProgress({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.isOwner,
    required super.isCollector,
    required super.propertySummaries,
    required super.pendingRequestIds,
    super.infoMessage,
  });
}

class NotificationsActionFailure extends NotificationsDataState {
  const NotificationsActionFailure({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.isOwner,
    required super.isCollector,
    required super.propertySummaries,
    required super.pendingRequestIds,
    required this.message,
    super.infoMessage,
  });

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}

class NotificationsActionSuccess extends NotificationsDataState {
  const NotificationsActionSuccess({
    required super.items,
    required super.lastDoc,
    required super.hasMore,
    required super.isOwner,
    required super.isCollector,
    required super.propertySummaries,
    required super.pendingRequestIds,
    super.infoMessage,
  });
}
