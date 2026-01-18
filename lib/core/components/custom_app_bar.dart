import 'package:flutter/material.dart';
import 'package:real_state/features/notifications/presentation/widgets/notifications_icon_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  final bool showNotificationIcon;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.showNotificationIcon = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = theme.appBarTheme.backgroundColor ?? colorScheme.surface;
    final fg = theme.appBarTheme.foregroundColor ?? colorScheme.onSurface;
    final outline = colorScheme.outlineVariant;

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: fg,
        ),
      ),
      leading: leading,
      backgroundColor: bg,
      surfaceTintColor: bg,
      elevation: theme.appBarTheme.elevation ?? 0,
      //shadowColor: Colors.black.withValues(alpha: 0.04),
      centerTitle: true,
      actions: [
        if (showNotificationIcon) const NotificationsIconButton(),
        ...?actions,
      ],
      iconTheme: theme.iconTheme.copyWith(color: fg),
      shape: Border(
        bottom: BorderSide(color: outline.withValues(alpha: 0.6), width: 1),
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
