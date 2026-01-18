import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/property_owner_scope.dart';
import '../../../models/entities/property.dart';

class PropertyDto {
  PropertyDto._();

  static Property fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    PropertyPurpose purposeFrom(String? s) =>
        (s == 'rent') ? PropertyPurpose.rent : PropertyPurpose.sale;
    PropertyStatus statusFrom(String? s) =>
        (s == 'archived') ? PropertyStatus.archived : PropertyStatus.active;
    PropertyOwnerScope ownerScopeFrom(String? s) => (s == 'broker')
        ? PropertyOwnerScope.broker
        : PropertyOwnerScope.company;

    return Property(
      id: doc.id,
      title: data['title'] as String?,
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : null,
      description: data['description'] as String?,
      purpose: purposeFrom(data['purpose'] as String?),
      rooms:
          (data['rooms'] as int?) ??
          (data['rooms'] is double ? (data['rooms'] as double).toInt() : null),
      kitchens:
          (data['kitchens'] as int?) ??
          (data['kitchens'] is double
              ? (data['kitchens'] as double).toInt()
              : null),
      floors:
          (data['floors'] as int?) ??
          (data['floors'] is double
              ? (data['floors'] as double).toInt()
              : null),
      hasPool: (data['hasPool'] as bool?) ?? false,
      locationAreaId: data['locationAreaId'] as String?,
      locationUrl: data['locationUrl'] as String?,
      coverImageUrl: data['coverImageUrl'] as String?,
      imageUrls: List<String>.from((data['imageUrls'] as List?) ?? const []),
      ownerPhoneEncryptedOrHiddenStored:
          data['ownerPhoneEncryptedOrHiddenStored'] as String?,
      securityGuardPhoneEncryptedOrHiddenStored:
          data['securityGuardPhoneEncryptedOrHiddenStored'] as String?,
      securityNumberEncryptedOrHiddenStored:
          data['securityNumberEncryptedOrHiddenStored'] as String?,
      isImagesHidden: (data['isImagesHidden'] as bool?) ?? false,
      status: statusFrom(data['status'] as String?),
      isDeleted: (data['isDeleted'] as bool?) ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      creatorName: data['creatorName'] as String?,
      ownerScope: ownerScopeFrom(data['ownerScope'] as String?),
      brokerId: data['brokerId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  static Map<String, Object?> toMap(Property p) => {
    'title': p.title,
    'price': p.price,
    'description': p.description,
    'purpose': p.purpose.name,
    'rooms': p.rooms,
    'kitchens': p.kitchens,
    'floors': p.floors,
    'hasPool': p.hasPool,
    'locationAreaId': p.locationAreaId,
    'locationUrl': p.locationUrl,
    'coverImageUrl': p.coverImageUrl,
    'imageUrls': p.imageUrls,
    'ownerPhoneEncryptedOrHiddenStored': p.ownerPhoneEncryptedOrHiddenStored,
    'securityGuardPhoneEncryptedOrHiddenStored':
        p.securityGuardPhoneEncryptedOrHiddenStored,
    'securityNumberEncryptedOrHiddenStored':
        p.securityNumberEncryptedOrHiddenStored,
    'isImagesHidden': p.isImagesHidden,
    'status': p.status.name,
    'isDeleted': p.isDeleted,
    'createdBy': p.createdBy,
    'creatorName': p.creatorName,
    'ownerScope': p.ownerScope.name,
    'brokerId': p.brokerId,
    'createdAt': Timestamp.fromDate(p.createdAt),
    'updatedAt': Timestamp.fromDate(p.updatedAt),
    'updatedBy': p.updatedBy,
  };
}
