import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/categories/domain/usecases/apply_property_filter_usecase.dart';

class CategoriesFilterController {
  const CategoriesFilterController();

  PropertyFilterValidationResult validate(PropertyFilter filter) {
    return const ApplyPropertyFilterUseCase()(filter);
  }
}
