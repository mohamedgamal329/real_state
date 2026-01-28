import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/domain/services/notification_messaging_service.dart';
import 'package:real_state/features/notifications/domain/usecases/handle_foreground_notification_usecase.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/flows/notification_flow.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';

class NotificationInitializer extends StatefulWidget {
  const NotificationInitializer({
    super.key,
    required this.child,
    required this.router,
  });

  final Widget child;
  final GoRouter router;

  @override
  State<NotificationInitializer> createState() =>
      _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  late final NotificationsBloc _notificationsBloc;
  late final NotificationFlow _notificationFlow;
  bool _configured = false;

  @override
  void initState() {
    super.initState();
    _notificationsBloc = NotificationsBloc(
      context.read<NotificationsRepository>(),
      context.read<AuthRepositoryDomain>(),
      context.read<NotificationMessagingService>(),
      context.read<PropertiesRepository>(),
      context.read<LocationAreasRepository>(),
      context.read<AcceptAccessRequestUseCase>(),
      context.read<RejectAccessRequestUseCase>(),
    );
    _notificationFlow = NotificationFlow(
      bloc: _notificationsBloc,
      backgroundUseCase: context.read<HandleForegroundNotificationUseCase>(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _configured) return;
      _configured = true;
      _notificationFlow.configure(
        context: context,
        router: widget.router,
      );
    });
  }

  @override
  void dispose() {
    _notificationFlow.dispose();
    _notificationsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
