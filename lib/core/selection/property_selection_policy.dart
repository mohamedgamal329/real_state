import 'package:flutter/foundation.dart';

/// Actions that can be shown when properties are selected.
enum PropertyBulkAction { share, archive, delete, restore }

/// Configuration for what bulk actions a selection flow exposes.
@immutable
class PropertySelectionPolicy {
  final List<PropertyBulkAction> actions;

  const PropertySelectionPolicy({this.actions = const []});
}
