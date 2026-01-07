import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../components/custom_app_bar.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'not_found'),
      body: Center(child: Text('page_not_found'.tr())),
    );
  }
}
