import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/location_area.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/notifications/data/services/fcm_service.dart';
import 'package:real_state/features/notifications/domain/entities/app_notification.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/cubit/access_request_action_cubit.dart';
import 'package:real_state/features/notifications/presentation/dialogs/access_request_dialog.dart';
import 'package:real_state/features/notifications/presentation/models/notification_property_summary.dart';
import 'package:real_state/features/properties/data/datasources/location_area_remote_datasource.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';
import 'package:real_state/features/users/data/repositories/users_repository.dart';

class NotificationCoordinator {
  bool _configured = false;
  StreamSubscription? _authSub;
  StreamSubscription<AppNotification>? _tapSub;
  StreamSubscription<AppNotification>? _fgSub;
  late BuildContext _context;
  late GoRouter _router;
  final Map<String, NotificationPropertySummary> _propertyCache = {};
  final Map<String, LocationArea> _areaCache = {};
  final Map<String, String> _requesterCache = {};
  String? _activeDialogRequestId;
  UserRole? _currentRole;
  String? _currentUserId;
  AppNotification? _pendingTappedNotification;

  Future<void> configure({required BuildContext context, required GoRouter router}) async {
    if (_configured) return;
    _configured = true;
    _context = context;
    _router = router;

    final fcm = context.read<FcmService>();
    final auth = context.read<AuthRepositoryDomain>();
    final repo = context.read<NotificationsRepository>();

    await fcm.initialize();

    _authSub = auth.userChanges.listen((user) {
      fcm.attachUser(user?.id);
      _currentRole = user?.role;
      _currentUserId = user?.id;
    });

    _tapSub = fcm.notificationTaps.listen((notification) async {
      _pendingTappedNotification = notification;
      await _handleTappedNotification(notification, router);
      unawaited(repo.markAsRead(notification.id));
    });

    _fgSub = fcm.foregroundNotifications.listen((notification) async {
      await _handleForegroundNotification(context, notification);
    });

    final initial = await fcm.initialMessage();
    if (initial != null) {
      _pendingTappedNotification = initial;
      await _handleTappedNotification(initial, router);
      unawaited(repo.markAsRead(initial.id));
    }
  }

  void dispose() {
    _authSub?.cancel();
    _tapSub?.cancel();
    _fgSub?.cancel();
  }

  void _handleNavigation(AppNotification notification, GoRouter router) {
    if (notification.type == AppNotificationType.general) return;
    final propertyId = notification.propertyId;
    if (propertyId == null || propertyId.isEmpty) return;
    router.push('/property/$propertyId');
  }

  Future<void> _handleTappedNotification(AppNotification notification, GoRouter router) async {
    if (_currentRole == UserRole.collector &&
        notification.type == AppNotificationType.accessRequest) {
      final canOpen = await _collectorCanOpenAccessRequest(notification);
      if (!canOpen) {
        AppSnackbar.show(_context, 'access_denied'.tr(), isError: true);
        return;
      }
    }
    if (_shouldShowAccessDialog(notification)) {
      _handleNavigation(notification, router);
      await _showAccessRequestDialog(notification);
      return;
    }
    _handleNavigation(notification, router);
  }

  Future<void> _handleForegroundNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    if (_shouldShowAccessDialog(notification)) {
      await _showAccessRequestDialog(notification);
      return;
    }
    final message = notification.body.isNotEmpty ? notification.body : notification.title;
    AppSnackbar.show(context, message);
  }

  bool _shouldShowAccessDialog(AppNotification notification) {
    if (!canShowAccessRequestDialog(_currentRole)) return false;
    if (notification.targetUserId != null && notification.targetUserId!.isNotEmpty) {
      if (_currentUserId == null || notification.targetUserId != _currentUserId) return false;
    }
    if (notification.requestStatus != null &&
        notification.requestStatus != AccessRequestStatus.pending) {
      return false;
    }
    final isAccessRequest =
        notification.type == AppNotificationType.accessRequest &&
        (notification.requestId?.isNotEmpty ?? false);
    if (!isAccessRequest) return false;
    if (_pendingTappedNotification == null) {
      // Foreground case
      return true;
    }
    // If notification came from tap or initial message, show once and clear pending.
    final shouldShow = _pendingTappedNotification?.id == notification.id;
    if (shouldShow) {
      _pendingTappedNotification = null;
    }
    return shouldShow;
  }

  Future<bool> _collectorCanOpenAccessRequest(AppNotification notification) async {
    if (notification.propertyId == null || notification.propertyId!.isEmpty) return false;
    try {
      final property = await _context.read<PropertiesRepository>().getById(
        notification.propertyId!,
      );
      if (property == null) return false;
      return property.ownerScope == PropertyOwnerScope.company;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showAccessRequestDialog(AppNotification notification) async {
    final requestId = notification.requestId;
    if (requestId == null) return;
    if (_activeDialogRequestId == requestId) return;
    _activeDialogRequestId = requestId;
    final dialogContext = _router.routerDelegate.navigatorKey.currentContext ?? _context;

    final summary = await _loadPropertySummary(dialogContext, notification);

    final requesterName = await _resolveRequesterName(notification, dialogContext);

    await showDialog(
      context: dialogContext,
      barrierDismissible: true,
      builder: (_) => BlocProvider(
        create: (ctx) => AccessRequestActionCubit(
          ctx.read<AcceptAccessRequestUseCase>(),
          ctx.read<RejectAccessRequestUseCase>(),
          ctx.read<NotificationsRepository>(),
          ctx.read<AuthRepositoryDomain>(),
        ),
        child: AccessRequestDialog(
          notification: notification,
          propertySummary: summary,
          requesterName: requesterName,
          onCompleted: () => _refreshNotificationsIfAvailable(dialogContext),
        ),
      ),
    );

    _activeDialogRequestId = null;
  }

  Future<NotificationPropertySummary> _loadPropertySummary(
    BuildContext context,
    AppNotification notification,
  ) async {
    final propertyId = notification.propertyId;
    if (propertyId == null || propertyId.isEmpty) {
      return const NotificationPropertySummary(title: 'property_unavailable', isMissing: true);
    }
    if (_propertyCache.containsKey(propertyId)) {
      return _propertyCache[propertyId]!;
    }

    Property? property;
    try {
      property = await context.read<PropertiesRepository>().getById(propertyId);
    } catch (e, st) {
      debugPrint('[NotificationCoordinator] property fetch failed: $e\n$st');
    }
    if (property == null) {
      final missing = const NotificationPropertySummary(
        title: 'property_unavailable',
        isMissing: true,
      );
      _propertyCache[propertyId] = missing;
      return missing;
    }

    LocationArea? area;
    final areaId = property.locationAreaId;
    if (areaId != null && areaId.isNotEmpty) {
      area = _areaCache[areaId];
      if (area == null) {
        try {
          final names = await context.read<LocationAreaRemoteDataSource>().fetchNamesByIds([
            areaId,
          ]);
          area = names[areaId];
          if (area != null) {
            _areaCache[areaId] = area;
          }
        } catch (e, st) {
          debugPrint('[NotificationCoordinator] area fetch failed: $e\n$st');
        }
      }
    }

    final summary = NotificationPropertySummary(
      title: property.title ?? '',
      areaName: area?.localizedName(),
      purposeKey: 'purpose.${property.purpose.name}',
      coverImageUrl: property.coverImageUrl,
      price: property.price,
    );
    _propertyCache[propertyId] = summary;
    return summary;
  }

  void _refreshNotificationsIfAvailable(BuildContext context) {
    try {
      final bloc = BlocProvider.of<NotificationsBloc>(context, listen: false);
      bloc.loadFirstPage();
    } catch (_) {}
  }

  Future<String> _resolveRequesterName(AppNotification notification, BuildContext context) async {
    if (notification.requesterName != null && notification.requesterName!.isNotEmpty) {
      return notification.requesterName!;
    }
    if (notification.requesterId == null || notification.requesterId!.isEmpty) return '';
    final requesterId = notification.requesterId!;
    if (_requesterCache.containsKey(requesterId)) return _requesterCache[requesterId] ?? '';
    try {
      final user = await context.read<UsersRepository>().getById(requesterId);
      final name = user.name?.isNotEmpty == true
          ? user.name!
          : (user.email?.isNotEmpty == true ? user.email! : '');
      _requesterCache[requesterId] = name;
      return name;
    } catch (e) {
      return '';
    }
  }
}
