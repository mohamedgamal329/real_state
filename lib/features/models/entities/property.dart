import 'package:meta/meta.dart';
import 'package:real_state/features/properties/domain/property_owner_scope.dart';

enum PropertyPurpose { sale, rent }

enum PropertyStatus { active, archived }

@immutable
class Property {
  final String id;
  final String? title;
  final String? description;
  final PropertyPurpose purpose;
  final int? rooms;
  final int? kitchens;
  final int? floors;
  final bool hasPool;
  final String? locationAreaId;
  final String? locationUrl;
  final String? coverImageUrl;
  final List<String> imageUrls;
  final double? price;

  // Stored as string but should never be exposed by default in DTO->UI
  final String? ownerPhoneEncryptedOrHiddenStored;
  final String? securityNumberEncryptedOrHiddenStored;
  final bool isImagesHidden;

  final PropertyStatus status;
  final bool isDeleted;

  final String createdBy;
  final String? creatorName;
  final PropertyOwnerScope ownerScope;
  final String? brokerId;

  final DateTime createdAt;
  final DateTime updatedAt;
  final String? updatedBy;

  const Property({
    required this.id,
    this.title,
    this.description,
    this.price,
    required this.purpose,
    this.rooms,
    this.kitchens,
    this.floors,
    this.hasPool = false,
    this.locationAreaId,
    this.locationUrl,
    this.coverImageUrl,
    this.imageUrls = const [],
    this.ownerPhoneEncryptedOrHiddenStored,
    this.securityNumberEncryptedOrHiddenStored,
    this.isImagesHidden = false,
    this.status = PropertyStatus.active,
    this.isDeleted = false,
    required this.createdBy,
    this.creatorName,
    this.ownerScope = PropertyOwnerScope.company,
    this.brokerId,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
  });
}
