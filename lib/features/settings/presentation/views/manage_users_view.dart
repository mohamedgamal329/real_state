import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_event.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_users_cubit.dart';
import 'package:real_state/features/settings/presentation/flows/manage_users_flow.dart';
import 'package:real_state/features/settings/presentation/views/manage_users_list.dart';
import 'package:real_state/features/settings/presentation/views/manage_users_tabs.dart';
import 'package:real_state/features/settings/presentation/widgets/user_list_item.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key, required this.flow});

  final ManageUsersFlow flow;

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final TabController _tabController;
  bool _initialized = false;
  bool _loadingRole = true;
  bool _isOwner = false;
  static const collectorsTabKey = ValueKey('manage_users_tab_collectors');
  static const brokersTabKey = ValueKey('manage_users_tab_brokers');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRole());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final auth = context.read<AuthRepositoryDomain>();
    final user = auth.currentUser ?? await auth.userChanges.first;
    setState(() {
      _isOwner = user?.role == UserRole.owner;
      _loadingRole = false;
    });
    if (!_isOwner && mounted) {
      AppSnackbar.show(
        context,
        'access_denied_owner'.tr(),
        type: AppSnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return Scaffold(
        appBar: CustomAppBar(title: 'manage_users'.tr()),
        body: _buildSkeletonList(),
      );
    }
    if (!_isOwner) {
      return Scaffold(
        appBar: CustomAppBar(title: 'manage_users'.tr()),
        body: AppErrorView(
          message: 'access_denied_owner'.tr(),
          onRetry: _loadRole,
        ),
      );
    }

    return BlocProvider(
      create: (context) => ManageUsersCubit(
        context.read<UserManagementRepository>(),
        isOwner: _isOwner,
      ),
      child: BlocConsumer<ManageUsersCubit, ManageUsersState>(
        listener: (context, state) {
          if (state is ManageUsersFailure) {
            AppSnackbar.show(
              context,
              state.message,
              type: AppSnackbarType.error,
            );
          } else if (state is ManageUsersPartialFailure) {
            AppSnackbar.show(
              context,
              state.message,
              type: AppSnackbarType.error,
            );
          } else if (state is ManageUsersLoadSuccess) {
            context.read<BrokersListBloc>().add(const BrokersListRefreshed());
          }
        },
        builder: (context, state) {
          if (!_initialized) {
            _initialized = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<ManageUsersCubit>().load();
            });
          }
          final dataState = state is ManageUsersLoadSuccess ? state : null;
          final isInitialLoading =
              state is ManageUsersInitial || state is ManageUsersLoadInProgress;
          final isActionInProgress = state is ManageUsersActionInProgress;
          final showSkeleton = isInitialLoading || isActionInProgress;

          if (state is ManageUsersFailure && dataState == null) {
            return Scaffold(
              appBar: CustomAppBar(title: 'manage_users'.tr()),
              body: AppErrorView(
                message: state.message,
                onRetry: () => context.read<ManageUsersCubit>().load(),
              ),
            );
          }

          final list = _tabIndex == 0
              ? (dataState?.collectors ?? const <ManagedUser>[])
              : (dataState?.brokers ?? const <ManagedUser>[]);
          final displayList = showSkeleton
              ? _placeholderUsers(
                  role: _tabIndex == 0 ? UserRole.collector : UserRole.broker,
                )
              : list;
          return Scaffold(
            appBar: CustomAppBar(title: 'manage_users'.tr()),
            floatingActionButton: _isOwner
                ? FloatingActionButton(
                    onPressed: () => widget.flow.openCreateUserSheet(context),
                    child: const AppSvgIcon(AppSVG.add),
                  )
                : null,
            body: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  ManageUsersTabs(
                    controller: _tabController,
                    onTap: (i) => setState(() => _tabIndex = i),
                    collectorsTabKey: collectorsTabKey,
                    brokersTabKey: brokersTabKey,
                  ),
                  Expanded(
                    child: ManageUsersList(
                      flow: widget.flow,
                      displayList: displayList,
                      showSkeleton: showSkeleton,
                      canAssignOwner: _isOwner,
                      onRetry: () => context.read<ManageUsersCubit>().load(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    final placeholders = _placeholderUsers(role: UserRole.collector);
    return Column(
      children: [
        ManageUsersTabs(controller: _tabController),
        Expanded(
          child: AppSkeletonList(
            itemCount: placeholders.length,
            itemBuilder: (_, i) => UserListItem(
              user: placeholders[i],
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ],
    );
  }

  List<ManagedUser> _placeholderUsers({required UserRole role}) {
    return List.generate(
      6,
      (i) => ManagedUser(
        id: 'placeholder-$i',
        role: role,
        name: 'loading_user'.tr(),
        email: 'user$i@email.com',
      ),
    );
  }
}
