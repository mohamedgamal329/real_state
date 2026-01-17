import 'package:flutter/material.dart';
import 'package:real_state/core/components/base_gradient_page.dart';

class ArchivePropertiesView extends StatelessWidget {
  final PreferredSizeWidget appBar;
  final Widget body;

  const ArchivePropertiesView({
    super.key,
    required this.appBar,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: BaseGradientPage(child: body),
    );
  }
}
