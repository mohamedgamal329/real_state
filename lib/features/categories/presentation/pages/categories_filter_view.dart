import 'package:flutter/material.dart';

class CategoriesFilterView extends StatelessWidget {
  final Widget form;

  const CategoriesFilterView({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: form,
      ),
    );
  }
}
