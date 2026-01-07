import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/core/components/custom_app_bar.dart';

class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onShare;

  const SelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onShare,
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
          icon: const Icon(Icons.close),
          onPressed: onClearSelection,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: onShare,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
