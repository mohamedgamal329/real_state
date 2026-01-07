import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({super.key, required this.title, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = theme.appBarTheme.backgroundColor ?? colorScheme.surface;
    final fg = theme.appBarTheme.foregroundColor ?? colorScheme.onSurface;
    final outline = colorScheme.outlineVariant;

    return AppBar(
      title: Text(
        title.tr(),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: fg,
        ),
      ),
      backgroundColor: bg,
      surfaceTintColor: bg,
      elevation: 0,
      //shadowColor: Colors.black.withValues(alpha: 0.04),
      centerTitle: true,
      actions: actions,
      iconTheme: theme.iconTheme.copyWith(color: fg),
      shape: Border(bottom: BorderSide(color: outline, width: 1)),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
