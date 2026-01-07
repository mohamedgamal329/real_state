import 'package:flutter/material.dart';
import 'package:real_state/core/widgets/app_select_item.dart';

/// iOS-style picker presented in a modal bottom sheet.
/// Does not replace existing dropdowns yet; intended for incremental adoption.
class AppDropdown<T> extends FormField<T> {
  AppDropdown({
    super.key,
    required T? value,
    required List<AppSelectItem<T>> items,
    required ValueChanged<T> onChanged,
    String? labelText,
    String? hintText,
    bool isRequired = false,
    bool enabled = true,
    FormFieldValidator<T>? validator,
    String? helperText,
    String? errorText,
    bool loading = false,
    String emptyText = 'No options',
  }) : super(
         initialValue: value,
         enabled: enabled,
         validator: validator,
         builder: (state) {
           return _AppDropdownField<T>(
             value: value,
             items: items,
             labelText: labelText,
             hintText: hintText,
             isRequired: isRequired,
             enabled: enabled,
             helperText: helperText,
             errorText: state.errorText ?? errorText,
             loading: loading,
             emptyText: emptyText,
             onChanged: (val) {
               state.didChange(val);
               onChanged(val);
             },
           );
         },
       );
}

class _AppDropdownField<T> extends StatefulWidget {
  final T? value;
  final List<AppSelectItem<T>> items;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final bool enabled;
  final String? helperText;
  final String? errorText;
  final bool loading;
  final String emptyText;
  final ValueChanged<T> onChanged;

  const _AppDropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.enabled = true,
    this.helperText,
    this.errorText,
    this.loading = false,
    this.emptyText = 'No options',
  });

  @override
  State<_AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<_AppDropdownField<T>> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final errorText = widget.errorText;
    final helperText = widget.helperText;
    final selectedLabel = _labelForValue(widget.value);
    final displayLabel = widget.labelText != null
        ? widget.isRequired
              ? '${widget.labelText!} *'
              : widget.labelText!
        : null;

    return GestureDetector(
      onTap: widget.enabled ? _openSheet : null,
      child: InputDecorator(
        isEmpty: selectedLabel == null || selectedLabel.isEmpty,
        isFocused: false,
        decoration: InputDecoration(
          labelText: displayLabel,
          hintText: widget.hintText,
          helperText: helperText,
          errorText: errorText,
          enabled: widget.enabled,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: theme.colorScheme.primary),
          ),
          disabledBorder: border,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        child: selectedLabel != null
            ? Text(
                selectedLabel,
                style: widget.enabled
                    ? theme.textTheme.bodyMedium
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  String? _labelForValue(T? value) {
    if (value == null) return null;
    final match = widget.items.where((e) => e.value == value).toList();
    if (match.isEmpty) return null;
    return match.first.label;
  }

  void _openSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final items = widget.items;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.labelText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Text(
                      widget.labelText!,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                if (widget.loading)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: SizedBox(
                      height: 32,
                      width: 32,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      widget.emptyText,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = widget.value == item.value;
                        return ListTile(
                          title: Text(item.label),
                          trailing: selected
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            widget.onChanged(item.value);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
