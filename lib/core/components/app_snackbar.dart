import 'package:flutter/material.dart';

class AppSnackbar {
  AppSnackbar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isError
        ? Colors.redAccent.withValues(alpha: 0.95)
        : colorScheme.primary.withValues(alpha: 0.9);
    final fg = Colors.white;
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: fg,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      duration: const Duration(milliseconds: 2600),
      elevation: 4,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
