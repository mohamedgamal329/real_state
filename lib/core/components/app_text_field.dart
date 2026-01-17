import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

/// Consistent text input with rounded border and optional validation.
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController? safeController = controller;
    if (safeController != null) {
      try {
        // Accessing .value is the standard way to check for disposal in Flutter.
        // If it throws, the controller is dead and we MUST NOT pass it to TextFormField.
        // ignore: unused_local_variable
        final _ = safeController.value;
      } catch (_) {
        safeController = null;
      }
    }
    final defaultSubmit = textInputAction == TextInputAction.next
        ? (String _) => FocusScope.of(context).nextFocus()
        : null;
    final theme = Theme.of(context);
    final decoration = theme.inputDecorationTheme;
    const radius = 14.0;

    return TextFormField(
      controller: safeController,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUnfocus,
      maxLines: maxLines,
      validator: validator,
      textInputAction: textInputAction,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),

      onFieldSubmitted: onFieldSubmitted ?? defaultSubmit,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor:
            decoration.fillColor ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: decoration.enabledBorder is OutlineInputBorder
                ? (decoration.enabledBorder as OutlineInputBorder)
                      .borderSide
                      .color
                : theme.colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: decoration.focusedBorder is OutlineInputBorder
                ? (decoration.focusedBorder as OutlineInputBorder)
                      .borderSide
                      .color
                : theme.colorScheme.primary,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
        ),
        errorStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
