import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/core/pagination/page_token.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/categories/domain/entities/property_filter.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';

/// Retrieves a paginated page of properties for a specific broker scope.
class GetBrokerPropertiesPageUseCase {
  final PropertiesRepository _repository;
  final AuthRepositoryDomain _auth;

  GetBrokerPropertiesPageUseCase(this._repository, this._auth);

  Future<PageResult<Property>> call({
    required String brokerId,
    PageToken? startAfter,
    int limit = 20,
    PropertyFilter? filter,
  }) {
    return _auth.userChanges.first.then((user) async {
      if (user?.role == UserRole.collector) {
        throw const LocalizedException('access_denied_broker_data');
      }
      return _repository.fetchBrokerPage(
        brokerId: brokerId,
        startAfter: startAfter,
        limit: limit,
        filter: filter,
        role: user?.role,
      );
    });
  }
}
