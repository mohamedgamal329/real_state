import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:real_state/features/splash/presentation/widgets/splash_logo.dart';

class LoginHeader extends StatelessWidget {
  final String titleKey;
  final String subtitleKey;

  const LoginHeader({
    super.key,
    this.titleKey = 'welcome_back',
    this.subtitleKey = 'sign_in_prompt',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(width: 90, height: 90),
        const SizedBox(height: 12),
        Text(
          titleKey.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(subtitleKey.tr(), textAlign: TextAlign.center),
      ],
    );
  }
}
