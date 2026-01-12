import 'package:flutter/foundation.dart';

/// Lightweight controller that tracks selected property IDs without knowing the
/// rest of the UI stack.
class PropertySelectionController {
  final ValueNotifier<Set<String>> selectedIds;
  bool _selectionEnabled = false;

  PropertySelectionController() : selectedIds = ValueNotifier(const {});

  bool get isSelectionActive =>
      _selectionEnabled && selectedIds.value.isNotEmpty;

  bool get isSelectionEnabled => _selectionEnabled;
  int get selectedCount => selectedIds.value.length;

  /// Toggles the selection state for [propertyId].
  void toggle(String propertyId) {
    if (!_selectionEnabled) {
      _selectionEnabled = true;
    }
    final current = Set<String>.from(selectedIds.value);
    if (current.contains(propertyId)) {
      current.remove(propertyId);
    } else {
      current.add(propertyId);
    }
    selectedIds.value = current;
    if (current.isEmpty) {
      _selectionEnabled = false;
    }
  }

  /// Clears the current selection and exits selection mode.
  void clear() {
    if (!_selectionEnabled && selectedIds.value.isEmpty) return;
    _selectionEnabled = false;
    selectedIds.value = const {};
  }

  bool isSelected(String propertyId) => selectedIds.value.contains(propertyId);

  void dispose() => selectedIds.dispose();
}
