import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class UpdatePropertyUseCase {
  final PropertiesRepository _repository;

  UpdatePropertyUseCase(this._repository);

  Future<Property> call({
    required Property existing,
    required String userId,
    required UserRole userRole,
    required String title,
    required String description,
    required PropertyPurpose purpose,
    required int? rooms,
    required int? kitchens,
    required int? floors,
    required bool hasPool,
    required String? locationAreaId,
    required double price,
    String? locationUrl,
    required String? ownerPhoneEncryptedOrHiddenStored,
    required String? securityNumberEncryptedOrHiddenStored,
    required bool isImagesHidden,
    required List<String> imageUrls,
    required String? coverImageUrl,
  }) {
    if (!canModifyProperty(
      property: existing,
      userId: userId,
      role: userRole,
    )) {
      throw const LocalizedException('access_denied');
    }
    return _repository.updateProperty(
      id: existing.id,
      userId: userId,
      userRole: userRole,
      title: title,
      description: description,
      purpose: purpose,
      rooms: rooms,
      kitchens: kitchens,
      floors: floors,
      hasPool: hasPool,
      locationAreaId: locationAreaId,
      price: price,
      locationUrl: locationUrl,
      ownerPhoneEncryptedOrHiddenStored: ownerPhoneEncryptedOrHiddenStored,
      securityNumberEncryptedOrHiddenStored:
          securityNumberEncryptedOrHiddenStored,
      isImagesHidden: isImagesHidden,
      imageUrls: imageUrls,
      coverImageUrl: coverImageUrl,
    );
  }
}
