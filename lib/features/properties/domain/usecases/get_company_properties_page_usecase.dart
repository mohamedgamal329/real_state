import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';

/// Retrieves a paginated page of company-scoped properties.
class GetCompanyPropertiesPageUseCase {
  final PropertiesRepository _repository;

  GetCompanyPropertiesPageUseCase(this._repository);

  Future<PageResult<Property>> call({
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) {
    return _repository.fetchCompanyPage(
      startAfter: startAfter,
      limit: limit,
      filter: filter,
    );
  }
}
