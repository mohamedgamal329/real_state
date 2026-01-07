import 'package:flutter/foundation.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';

/// Shared controller to manage property filters across list pages.
class PropertyFilterController extends ChangeNotifier {
  PropertyFilter _filter;

  PropertyFilterController({PropertyFilter? initial})
    : _filter = initial ?? const PropertyFilter();

  PropertyFilter get filter => _filter;

  bool get hasActiveFilters => !_filter.isEmpty;

  void apply(PropertyFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void clear() {
    _filter = const PropertyFilter();
    notifyListeners();
  }
}
