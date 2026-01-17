import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/models/entities/property.dart';
import 'package:real_state/features/properties/domain/repositories/properties_repository.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class CreatePropertyUseCase {
  final PropertiesRepository _repository;

  CreatePropertyUseCase(this._repository);

  Future<Property> call({
    required String id,
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
    required String? securityGuardPhoneEncryptedOrHiddenStored,
    required bool isImagesHidden,
    required List<String> imageUrls,
    required String? coverImageUrl,
  }) {
    if (!canCreateProperty(userRole)) {
      throw const LocalizedException('access_denied');
    }
    return _repository.createProperty(
      id: id,
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
      securityGuardPhoneEncryptedOrHiddenStored:
          securityGuardPhoneEncryptedOrHiddenStored,
      isImagesHidden: isImagesHidden,
      imageUrls: imageUrls,
      coverImageUrl: coverImageUrl,
    );
  }
}
