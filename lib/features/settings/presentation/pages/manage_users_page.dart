import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/animations/slide_fade_in.dart';
import 'package:real_state/core/components/app_confirm_dialog.dart';
import 'package:real_state/core/components/app_error_view.dart';
import 'package:real_state/core/components/app_skeleton_list.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/app_snackbar.dart';
import 'package:real_state/core/components/app_text_field.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/core/components/loading_dialog.dart';
import 'package:real_state/core/components/primary_button.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/validation/validators.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_bloc.dart';
import 'package:real_state/features/brokers/presentation/bloc/brokers_list_event.dart';
import 'package:real_state/features/settings/presentation/cubit/manage_users_cubit.dart';
import 'package:real_state/features/settings/presentation/widgets/user_list_item.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';
import 'package:real_state/features/users/domain/repositories/user_management_repository.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final TabController _tabController;
  bool _initialized = false;
  bool _loadingRole = true;
  bool _isOwner = false;

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
    final user = await auth.userChanges.first;
    setState(() {
      _isOwner = user?.role == UserRole.owner;
      _loadingRole = false;
    });
    if (!_isOwner && mounted) {
      AppSnackbar.show(context, 'access_denied_owner'.tr(), isError: true);
    }
  }

  Future<void> _showEditor(ManagedUser user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    var role = user.role;
    var previousRole = role;
    final formKey = GlobalKey<FormState>();
    final res = await showDialog<bool?>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text('edit_role'.tr(args: [_roleLabel(role)])),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom * 0.4, top: 8),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'name'.tr(),
                    controller: nameCtrl,
                    validator: (v) => Validators.isValidName(v) ? null : 'name_too_short'.tr(),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(label: 'phone'.tr(), controller: phoneCtrl),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    items: [
                      DropdownMenuItem(value: UserRole.collector, child: Text('collector'.tr())),
                      DropdownMenuItem(value: UserRole.broker, child: Text('broker'.tr())),
                      if (_isOwner)
                        DropdownMenuItem(value: UserRole.owner, child: Text('owner'.tr())),
                    ],
                    validator: (r) => Validators.isSelected(r) ? null : 'role_required'.tr(),
                    onChanged: (r) async {
                      if (r == null) return;
                      if (r == UserRole.owner && _isOwner) {
                        final confirmed = await _confirmOwnerAssignment(c);
                        if (!confirmed) {
                          setState(() => role = previousRole);
                          return;
                        }
                      }
                      setState(() {
                        previousRole = role;
                        role = r;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => c.pop(false), child: Text('cancel'.tr())),
            PrimaryButton(
              label: 'save'.tr(),
              expand: false,
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                c.pop(true);
              },
            ),
          ],
        ),
      ),
    );
    if (res != true) return;
    final cubit = context.read<ManageUsersCubit>();
    await LoadingDialog.show(
      context,
      cubit.update(
        id: user.id,
        name: nameCtrl.text.trim(),
        phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        role: role,
      ),
    );
  }

  Future<void> _delete(ManagedUser user) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'delete_user',
      descriptionKey: 'are_you_sure',
      confirmLabelKey: 'disable',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    if (result != AppConfirmResult.confirmed) return;
    await context.read<ManageUsersCubit>().delete(user.id);
    AppSnackbar.show(context, 'user_disabled'.tr());
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'manage_users'),
        body: _buildSkeletonList(),
      );
    }
    if (!_isOwner) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'manage_users'),
        body: AppErrorView(
          message: 'access_denied_owner'.tr(),
          onRetry: () => WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<ManageUsersCubit>().load();
          }),
        ),
      );
    }

    return BlocProvider(
      create: (context) =>
          ManageUsersCubit(context.read<UserManagementRepository>(), isOwner: _isOwner),
      child: BlocConsumer<ManageUsersCubit, ManageUsersState>(
        listener: (context, state) {
          if (state is ManageUsersFailure) {
            AppSnackbar.show(context, state.message, isError: true);
          } else if (state is ManageUsersPartialFailure) {
            AppSnackbar.show(context, state.message, isError: true);
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
              appBar: const CustomAppBar(title: 'manage_users'),
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
              ? _placeholderUsers(role: _tabIndex == 0 ? UserRole.collector : UserRole.broker)
              : list;
          return Scaffold(
            appBar: const CustomAppBar(title: 'manage_users'),
            floatingActionButton: _isOwner
                ? FloatingActionButton(
                    onPressed: () => _showCreateUserDialog(context),
                    child: const Icon(Icons.add),
                  )
                : null,
            body: AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'collectors'.tr()),
                      Tab(text: 'brokers'.tr()),
                    ],
                    onTap: (i) => setState(() => _tabIndex = i),
                    controller: _tabController,
                  ),
                  Expanded(
                    child: AppSkeletonizer(
                      enabled: showSkeleton,
                      child: displayList.isEmpty
                          ? EmptyStateWidget(
                              description: 'no_users_description'.tr(),
                              action: () => context.read<ManageUsersCubit>().load(),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: displayList.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (c, i) {
                                final u = displayList[i];
                                final canInteract = !showSkeleton;
                                return SlideFadeIn(
                                  delay: Duration(milliseconds: 40 * i),
                                  child: UserListItem(
                                    user: u,
                                    onEdit: canInteract ? () => _showEditor(u) : () {},
                                    onDelete: canInteract ? () => _delete(u) : () {},
                                  ),
                                );
                              },
                            ),
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

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.collector:
        return 'collectors'.tr();
      case UserRole.broker:
        return 'brokers'.tr();
      case UserRole.owner:
        return 'owner'.tr();
    }
  }

  Widget _buildSkeletonList() {
    final placeholders = _placeholderUsers(role: UserRole.collector);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'collectors'.tr()),
            Tab(text: 'brokers'.tr()),
          ],
        ),
        Expanded(
          child: AppSkeletonList(
            itemCount: placeholders.length,
            itemBuilder: (_, i) =>
                UserListItem(user: placeholders[i], onEdit: () {}, onDelete: () {}),
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

  Future<bool> _confirmOwnerAssignment(BuildContext context) async {
    final result = await AppConfirmDialog.show(
      context,
      titleKey: 'transfer_ownership',
      descriptionKey: 'ownership_transfer_warning',
      confirmLabelKey: 'confirm',
      cancelLabelKey: 'cancel',
      isDestructive: true,
    );
    return result == AppConfirmResult.confirmed;
  }

  Future<void> _showCreateUserDialog(BuildContext context) async {
    final emailCtrl = TextEditingController();
    UserRole? role = UserRole.collector;
    final formKey = GlobalKey<FormState>();

    final res = await showDialog<bool?>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text('add_user'.tr()),
          content: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom * 0.4, top: 8),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    label: 'email'.tr(),
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => Validators.isEmail(v) ? null : 'valid_email_required'.tr(),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: role,
                    items: [
                      DropdownMenuItem(value: UserRole.collector, child: Text('collector'.tr())),
                      DropdownMenuItem(value: UserRole.broker, child: Text('broker'.tr())),
                      DropdownMenuItem(value: UserRole.owner, child: Text('owner'.tr())),
                    ],
                    validator: (r) => Validators.isSelected(r) ? null : 'role_required'.tr(),
                    onChanged: (r) => setState(() => role = r),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => c.pop(false), child: Text('cancel'.tr())),
            PrimaryButton(
              label: 'add'.tr(),
              expand: false,
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                c.pop(true);
              },
            ),
          ],
        ),
      ),
    );
    if (res != true) return;
    final selectedRole = role;
    if (selectedRole == null) return;
    await LoadingDialog.show(
      context,
      context.read<ManageUsersCubit>().create(email: emailCtrl.text.trim(), role: selectedRole),
    );
  }
}
