import 'package:easy_localization/easy_localization.dart';

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) {
    return 'just_now'.tr();
  }
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? 'minute_ago'.tr() : 'minutes_ago'.tr(args: [m.toString()]);
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? 'hour_ago'.tr() : 'hours_ago'.tr(args: [h.toString()]);
  }
  final d = diff.inDays;
  return d == 1 ? 'day_ago'.tr() : 'days_ago'.tr(args: [d.toString()]);
}
