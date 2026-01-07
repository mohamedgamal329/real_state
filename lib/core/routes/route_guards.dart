import 'package:flutter/widgets.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/components/app_snackbar.dart';
import '../constants/user_role.dart';

class RouteGuards {
  const RouteGuards._();

  static String? guardCollector({
    required BuildContext context,
    required String location,
    required UserRole? role,
  }) {
    if (role != UserRole.collector) return null;
    final blocked = _isCollectorBlocked(location);
    if (!blocked) return null;
    AppSnackbar.show(context, 'access_denied_snackbar'.tr(), isError: true);
    return '/main';
  }

  static bool _isCollectorBlocked(String location) {
    if (location.startsWith('/broker/')) return true;
    if (location == '/settings/users' || location == '/settings/locations')
      return true;
    if (location == '/brokers') return true;
    return false;
  }
}
