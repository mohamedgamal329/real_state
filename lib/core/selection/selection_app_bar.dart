import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/custom_app_bar.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';

import 'property_selection_policy.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final PropertySelectionPolicy policy;
  final Map<PropertyBulkAction, VoidCallback> actionCallbacks;
  final VoidCallback onClearSelection;

  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.policy,
    required this.actionCallbacks,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final title = 'selected_count'.plural(
      selectedCount,
      args: [selectedCount.toString()],
    );

    return CustomAppBar(
      title: title,
      actions: [
        IconButton(
          icon: const AppSvgIcon(AppSVG.close),
          onPressed: onClearSelection,
        ),
        ...policy.actions
            .map((action) => _buildActionButton(context, action))
            .whereType<Widget>(),
      ],
    );
  }

  Widget? _buildActionButton(BuildContext context, PropertyBulkAction action) {
    final callback = actionCallbacks[action];
    if (callback == null) return null;
    return IconButton(
      icon: _iconFor(action),
      onPressed: callback,
      tooltip: _labelFor(action, context),
    );
  }

  Widget _iconFor(PropertyBulkAction action) {
    switch (action) {
      case PropertyBulkAction.share:
        return const AppSvgIcon(AppSVG.share);
      case PropertyBulkAction.archive:
        return const AppSvgIcon(AppSVG.archive);
      case PropertyBulkAction.delete:
        return const AppSvgIcon(AppSVG.delete);
      case PropertyBulkAction.restore:
        return const AppSvgIcon(AppSVG.restore);
    }
  }

  String _labelFor(PropertyBulkAction action, BuildContext context) {
    switch (action) {
      case PropertyBulkAction.share:
        return 'share'.tr();
      case PropertyBulkAction.archive:
        return 'archive'.tr();
      case PropertyBulkAction.delete:
        return 'delete'.tr();
      case PropertyBulkAction.restore:
        return 'restore'.tr();
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
