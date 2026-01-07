import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/animations/slide_fade_in.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/base_gradient_page.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/notifications/data/services/fcm_service.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:real_state/features/notifications/presentation/widgets/notification_card.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsBloc _bloc;
  late RefreshController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _bloc = NotificationsBloc(
      context.read<NotificationsRepository>(),
      context.read<AuthRepositoryDomain>(),
      context.read<FcmService>(),
      context.read<PropertiesRepository>(),
      context.read<LocationAreaRemoteDataSource>(),
      context.read<AcceptAccessRequestUseCase>(),
      context.read<RejectAccessRequestUseCase>(),
    )..add(const NotificationsStarted());
  }

  @override
  void dispose() {
    _bloc.close();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: const CustomAppBar(title: 'notifications'),
        body: BaseGradientPage(
          child: BlocConsumer<NotificationsBloc, NotificationsState>(
            listener: (context, state) {
              if (state is NotificationsLoading) {
                _refreshController.resetNoData();
              }
              if (state is NotificationsDataState &&
                  state.infoMessage != null) {
                AppSnackbar.show(context, state.infoMessage!);
                context.read<NotificationsBloc>().clearInfo();
              }
              if (state is NotificationsPartialFailure ||
                  state is NotificationsActionFailure) {
                final message = state is NotificationsPartialFailure
                    ? state.message
                    : (state as NotificationsActionFailure).message;
                AppSnackbar.show(context, message, isError: true);
              }
              if (state is NotificationsDataState) {
                _refreshController.refreshCompleted();
                if (state.hasMore) {
                  _refreshController.loadComplete();
                } else {
                  _refreshController.loadNoData();
                }
              } else if (state is NotificationsFailure) {
                _refreshController.refreshFailed();
                _refreshController.loadFailed();
              }
            },
            builder: (context, state) {
              final isInitialLoading =
                  state is NotificationsInitial ||
                  state is NotificationsLoading;
              final dataState = state is NotificationsDataState ? state : null;
              final pendingRequests =
                  dataState?.pendingRequestIds ?? const <String>{};
              final isOwner = state is NotificationsStateWithRole
                  ? state.isOwner
                  : false;
              final bloc = context.read<NotificationsBloc>();
              final currentUserId = bloc.currentUserId;
              final currentRole = bloc.currentRole;

              final items = dataState?.items ?? const <AppNotification>[];

              if (state is NotificationsFailure && items.isEmpty) {
                return AppErrorView(
                  message: state.message,
                  onRetry: () =>
                      context.read<NotificationsBloc>().loadFirstPage(),
                );
              }

              final listItems = isInitialLoading
                  ? _placeholderNotifications(isOwner)
                  : items;

              if (!isInitialLoading && items.isEmpty) {
                return EmptyStateWidget(
                  description: 'no_notifications_description'.tr(),
                  action: () =>
                      context.read<NotificationsBloc>().loadFirstPage(),
                );
              }

              return SmartRefresher(
                controller: _refreshController,
                enablePullUp: dataState?.hasMore ?? false,
                onRefresh: _onRefresh,
                onLoading: () => context.read<NotificationsBloc>().loadMore(),
                child: AppSkeletonizer(
                  enabled: isInitialLoading,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: listItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = listItems[index];
                      final canNavigate =
                          !isInitialLoading &&
                          n.type != AppNotificationType.general &&
                          n.propertyId != null &&
                          n.propertyId!.isNotEmpty;
                      final onTap = canNavigate
                          ? () {
                              context.read<NotificationsBloc>().markRead(n.id);
                              context.push('/property/${n.propertyId}');
                            }
                          : null;
                      final canAct =
                          !isInitialLoading &&
                          n.type == AppNotificationType.accessRequest &&
                          (n.requestId?.isNotEmpty ?? false) &&
                          (n.requestStatus == null ||
                              n.requestStatus == AccessRequestStatus.pending);
                      final allowActions =
                          canAcceptRejectAccessRequests(currentRole) &&
                          (n.targetUserId != null &&
                              n.targetUserId == currentUserId);
                      final isActionPending =
                          canAct && pendingRequests.contains(n.requestId ?? '');
                      final summary =
                          dataState?.propertySummaries[n.propertyId];
                      return SlideFadeIn(
                        delay: Duration(milliseconds: 30 * index),
                        child: NotificationCard(
                          notification: n,
                          isOwner: isOwner,
                          isTarget: allowActions,
                          showActions: allowActions,
                          propertySummary: summary,
                          onTap: onTap,
                          isActionInProgress:
                              isActionPending ||
                              state is NotificationsActionInProgress,
                          onAccept: allowActions && canAct && !isActionPending
                              ? () async => await LoadingDialog.show(
                                  context,
                                  bloc.accept(n.id, n.requestId!),
                                )
                              : null,
                          onReject: allowActions && canAct && !isActionPending
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
                                    await bloc.reject(n.id, n.requestId!);
                                  }
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onRefresh() {
    _refreshController.resetNoData();
    context.read<NotificationsBloc>().loadFirstPage();
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
