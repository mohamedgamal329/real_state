import 'package:flutter/material.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';
import 'package:real_state/features/users/domain/entities/managed_user.dart';

class UserListItem extends StatelessWidget {
  final ManagedUser user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserListItem({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('manage_user_${user.id}'),
      title: Text(user.name ?? user.email ?? ''),
      subtitle: Text(user.email ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: onEdit, icon: const AppSvgIcon(AppSVG.edit)),
          IconButton(
            onPressed: onDelete,
            icon: const AppSvgIcon(AppSVG.delete),
          ),
        ],
      ),
    );
  }
}
