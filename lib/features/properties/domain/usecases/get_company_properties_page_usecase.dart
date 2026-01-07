import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/features/categories/data/models/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';

/// Retrieves a paginated page of company-scoped properties.
class GetCompanyPropertiesPageUseCase {
  final PropertiesRepository _repository;

  GetCompanyPropertiesPageUseCase(this._repository);

  Future<PageResult<Property>> call({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
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
