import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/data/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class DeletePropertyUseCase {
  final PropertiesRepository _repository;

  DeletePropertyUseCase(this._repository);

  Future<void> call({
    required Property property,
    required String userId,
    required UserRole userRole,
  }) {
    if (!canArchiveOrDeleteProperty(
      property: property,
      userId: userId,
      role: userRole,
    )) {
      throw const LocalizedException('access_denied_delete');
    }
    return _repository.deleteProperty(
      id: property.id,
      userId: userId,
      userRole: userRole,
    );
  }
}
