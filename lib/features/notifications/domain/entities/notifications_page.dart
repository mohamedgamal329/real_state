import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';

class NotificationsPage {
  final List<AppNotification> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  NotificationsPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}
