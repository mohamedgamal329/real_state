import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/animations/slide_fade_in.dart';
import 'package:real_state/core/components/app_skeletonizer.dart';
import 'package:real_state/core/components/empty_state_widget.dart';
import 'package:real_state/features/settings/presentation/flows/manage_users_flow.dart';
import 'package:real_state/features/settings/presentation/widgets/user_list_item.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

class ManageUsersList extends StatelessWidget {
  final ManageUsersFlow flow;
  final List<ManagedUser> displayList;
  final bool showSkeleton;
  final bool canAssignOwner;
  final VoidCallback onRetry;

  const ManageUsersList({
    super.key,
    required this.flow,
    required this.displayList,
    required this.showSkeleton,
    required this.canAssignOwner,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer(
      enabled: showSkeleton,
      child: displayList.isEmpty
          ? EmptyStateWidget(
              description: 'no_users_description'.tr(),
              action: onRetry,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (c, i) {
                final user = displayList[i];
                final canInteract = !showSkeleton;
                return SlideFadeIn(
                  delay: Duration(milliseconds: 40 * i),
                  child: UserListItem(
                    user: user,
                    onEdit: canInteract
                        ? () => flow.openEditUserSheetOrDialog(
                            context,
                            user,
                            canAssignOwner: canAssignOwner,
                          )
                        : () {},
                    onDelete: canInteract
                        ? () => flow.confirmAndDeleteUser(context, user)
                        : () {},
                  ),
                );
              },
            ),
    );
  }
}
