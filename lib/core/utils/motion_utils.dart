import 'package:flutter/widgets.dart';

bool reduceMotion(BuildContext context) {
  if (const bool.fromEnvironment('FLUTTER_TEST')) return true;
  final mq = MediaQuery.maybeOf(context);
  if (mq == null) return false;
  return mq.disableAnimations || mq.accessibleNavigation;
}
