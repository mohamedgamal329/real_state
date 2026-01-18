import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../components/custom_app_bar.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'no_internet'.tr()),
      body: Center(child: Text('check_connection'.tr())),
    );
  }
}
