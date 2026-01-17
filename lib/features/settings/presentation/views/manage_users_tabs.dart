import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class ManageUsersTabs extends StatelessWidget {
  final TabController controller;
  final ValueChanged<int>? onTap;
  final Key? collectorsTabKey;
  final Key? brokersTabKey;

  const ManageUsersTabs({
    super.key,
    required this.controller,
    this.onTap,
    this.collectorsTabKey,
    this.brokersTabKey,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      onTap: onTap,
      tabs: [
        Tab(key: collectorsTabKey, text: 'collectors'.tr()),
        Tab(key: brokersTabKey, text: 'brokers'.tr()),
      ],
    );
  }
}
