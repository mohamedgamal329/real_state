import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/pages/notifications_list_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/pump_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('owner sees pending requests and can accept', (tester) async {
    final now = DateTime.now();
    final notification = AppNotification(
      id: 'n1',
      type: AppNotificationType.accessRequest,
      title: 'access_request_title',
      body: 'Message: please',
      createdAt: now,
      isRead: false,
      requesterName: 'u2',
      requestId: 'r1',
      requestStatus: AccessRequestStatus.pending,
      requestType: AccessRequestType.images,
      targetUserId: 'owner1',
      propertyId: 'p1',
      requestMessage: 'Message: please',
    );
    var accepted = false;
    var showActions = true;
    final refreshController = RefreshController();

    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          final item = NotificationListItem(
            viewModel: NotificationViewModel.fromNotification(
              notification: notification,
            ),
            isOwner: true,
            isTarget: true,
            showActions: showActions,
            actionStatus: NotificationActionStatus.idle,
            onAccept: () {
              setState(() {
                accepted = true;
                showActions = false;
              });
            },
            onReject: () {},
          );
          return NotificationListView(
            refreshController: refreshController,
            items: [item],
            isLoading: false,
            hasMore: false,
            onRefresh: () {},
            onLoadMore: () {},
            showError: false,
            onRetry: () {},
            emptyMessage: '',
          );
        },
      ),
    );

    final cardFinder = byKeyStr('notification_card_n1');
    expect(cardFinder, findsOneWidget);
    final acceptFinder = byKeyStr('notification_accept_n1');
    final rejectFinder = byKeyStr('notification_reject_n1');
    expect(acceptFinder, findsOneWidget);
    expect(rejectFinder, findsOneWidget);

    await tester.ensureVisible(acceptFinder);
    await tester.tap(acceptFinder, warnIfMissed: false);
    await tester.pump();
    expect(accepted, isTrue);
    expect(acceptFinder, findsNothing);
    expect(rejectFinder, findsNothing);
  });
}
