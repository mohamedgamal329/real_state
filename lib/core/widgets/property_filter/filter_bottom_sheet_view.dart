import 'package:flutter/material.dart';

class FilterBottomSheetView extends StatelessWidget {
  final Widget form;

  const FilterBottomSheetView({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: form,
        ),
      ),
    );
  }
}
