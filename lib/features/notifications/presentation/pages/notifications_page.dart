import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/notifications/domain/services/notification_messaging_service.dart';
import 'package:real_state/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:real_state/features/notifications/presentation/views/notifications_view.dart';
import 'package:real_state/features/location/domain/repositories/location_areas_repository.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final RefreshController _refreshController;
  late final NotificationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _refreshController = RefreshController();
    _bloc = NotificationsBloc(
      context.read<NotificationsRepository>(),
      context.read<AuthRepositoryDomain>(),
      context.read<NotificationMessagingService>(),
      context.read<PropertiesRepository>(),
      context.read<LocationAreasRepository>(),
      context.read<AcceptAccessRequestUseCase>(),
      context.read<RejectAccessRequestUseCase>(),
    );
    _bloc.loadFirstPage();
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
        appBar: CustomAppBar(title: 'notifications'.tr()),
        body: NotificationsView(
          refreshController: _refreshController,
          onRefresh: _onRefresh,
        ),
      ),
    );
  }

  void _onRefresh() {
    _refreshController.resetNoData();
    context.read<NotificationsBloc>().loadFirstPage();
  }
}
