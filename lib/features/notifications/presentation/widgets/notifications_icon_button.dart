import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:real_state/core/components/app_svg_icon.dart';
import 'package:real_state/core/constants/app_images.dart';

class NotificationsIconButton extends StatelessWidget {
  const NotificationsIconButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: AppSvgIcon(
        AppSVG.notifications,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
