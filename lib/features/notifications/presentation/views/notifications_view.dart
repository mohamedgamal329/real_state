import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:real_state/features/notifications/presentation/models/notification_action_status.dart';
import 'package:real_state/features/notifications/presentation/models/notification_view_model.dart';
import 'package:real_state/features/notifications/presentation/pages/notifications_list_view.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({
    super.key,
    required this.refreshController,
    required this.onRefresh,
  });

  final RefreshController refreshController;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return BaseGradientPage(
      child: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsLoading) {
            refreshController.resetNoData();
          }
          if (state is NotificationsDataState && state.infoMessage != null) {
            AppSnackbar.show(context, state.infoMessage!);
            context.read<NotificationsBloc>().clearInfo();
          }
          if (state is NotificationsPartialFailure ||
              state is NotificationsActionFailure) {
            final message = state is NotificationsPartialFailure
                ? state.message
                : (state as NotificationsActionFailure).message;
            final isNetwork = message == 'network_error'.tr();
            AppSnackbar.show(
              context,
              message,
              type: AppSnackbarType.error,
              actionLabel: isNetwork ? 'retry'.tr() : null,
              onAction: isNetwork ? onRefresh : null,
            );
          }
          if (state is NotificationsDataState) {
            refreshController.refreshCompleted();
            if (state.hasMore) {
              refreshController.loadComplete();
            } else {
              refreshController.loadNoData();
            }
          } else if (state is NotificationsFailure) {
            refreshController.refreshFailed();
            refreshController.loadFailed();
          }
        },
        builder: (context, state) {
          final isInitialLoading =
              state is NotificationsInitial || state is NotificationsLoading;
          final dataState = state is NotificationsDataState ? state : null;
          final isOwner = state is NotificationsStateWithRole
              ? state.isOwner
              : false;
          final items = isInitialLoading
              ? _placeholderNotifications(isOwner)
              : dataState?.items ?? const [];
          final pendingRequests = dataState?.pendingRequestIds ?? const {};
          final actionStatuses =
              dataState?.actionStatuses ??
              const <String, NotificationActionStatus>{};
          final bloc = context.read<NotificationsBloc>();
          final currentUserId = bloc.currentUserId;
          final currentRole = bloc.currentRole;

          final listItems = items.map((notification) {
            final summary =
                dataState?.propertySummaries[notification.propertyId];
            final viewModel = NotificationViewModel.fromNotification(
              notification: notification,
              propertySummary: summary,
            );
            final actionStatus =
                actionStatuses[notification.id] ??
                NotificationActionStatus.idle;
            final canNavigate =
                !isInitialLoading &&
                notification.type != AppNotificationType.general &&
                (notification.propertyId?.isNotEmpty ?? false);
            final canAct =
                !isInitialLoading &&
                notification.type == AppNotificationType.accessRequest &&
                (notification.requestId?.isNotEmpty ?? false) &&
                (notification.requestStatus == null ||
                    notification.requestStatus == AccessRequestStatus.pending);
            final isRequesterOfProperty =
                notification.requesterId != null &&
                notification.requesterId == currentUserId;

            final isTargetUser = notification.targetUserId == currentUserId;

            final allowActions =
                canAcceptRejectAccessRequests(currentRole) &&
                (isTargetUser || currentRole == UserRole.owner) &&
                !isRequesterOfProperty &&
                canAct;

            final isActionPending =
                canAct &&
                pendingRequests.contains(notification.requestId ?? '');
            final isActionBusy = actionStatus.isBusy || isActionPending;

            return NotificationListItem(
              viewModel: viewModel,
              isOwner: isOwner,
              isTarget: allowActions,
              showActions: allowActions,
              actionStatus: actionStatus,
              onTap: canNavigate
                  ? () {
                      bloc.markRead(notification.id);
                      unawaited(
                        context.push('/property/${notification.propertyId}'),
                      );
                    }
                  : null,
              onAccept:
                  allowActions &&
                      canAct &&
                      !isActionBusy &&
                      actionStatus == NotificationActionStatus.idle
                  ? () {
                      unawaited(
                        bloc.accept(notification.id, notification.requestId!),
                      );
                    }
                  : null,
              onReject:
                  allowActions &&
                      canAct &&
                      !isActionBusy &&
                      actionStatus == NotificationActionStatus.idle
                  ? () async {
                      final result = await AppConfirmDialog.show(
                        context,
                        titleKey: 'reject',
                        descriptionKey: 'are_you_sure',
                        confirmLabelKey: 'reject',
                        cancelLabelKey: 'cancel',
                        isDestructive: true,
                      );
                      if (result == AppConfirmResult.confirmed) {
                        unawaited(
                          bloc.reject(notification.id, notification.requestId!),
                        );
                      }
                    }
                  : null,
            );
          }).toList();

          final showError = state is NotificationsFailure && items.isEmpty;
          final errorMessage = state is NotificationsFailure
              ? state.message
              : null;

          return NotificationListView(
            refreshController: refreshController,
            isLoading: isInitialLoading,
            hasMore: dataState?.hasMore ?? false,
            items: listItems,
            onRefresh: onRefresh,
            onLoadMore: () => bloc.loadMore(),
            showError: showError,
            errorMessage: errorMessage,
            onRetry: () => bloc.loadFirstPage(),
            emptyMessage: 'no_notifications_description'.tr(),
          );
        },
      ),
    );
  }

  List<AppNotification> _placeholderNotifications(bool isOwner) {
    return List.generate(6, (i) {
      final isAccess = i.isOdd;
      return AppNotification(
        id: 'placeholder-$i',
        type: isAccess
            ? AppNotificationType.accessRequest
            : AppNotificationType.general,
        title: 'loading_notification'.tr(),
        body: 'loading_details'.tr(),
        createdAt: DateTime.now(),
        isRead: false,
        propertyId: isAccess ? 'property-$i' : null,
        requesterId: isAccess ? 'user-$i' : null,
        requestId: isAccess ? 'request-$i' : null,
        requestType: isAccess ? AccessRequestType.images : null,
        requestStatus: isAccess && isOwner ? AccessRequestStatus.pending : null,
      );
    });
  }
}
