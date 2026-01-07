import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/location_area.dart';

class LocationAreaDto {
  LocationAreaDto._();

  static LocationArea fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LocationArea(
      id: doc.id,
      nameAr: data['name_ar'] as String? ?? data['nameAr'] as String? ?? '',
      nameEn:
          data['name_en'] as String? ??
          data['nameEn'] as String? ??
          data['name'] as String? ??
          '',
      imageUrl:
          data['imageUrl'] as String? ??
          data['image_url'] as String? ??
          data['image'] as String? ??
          '',
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, Object?> toMap(LocationArea area) => {
    'name': area.nameEn,
    'name_ar': area.nameAr,
    'name_en': area.nameEn,
    'imageUrl': area.imageUrl,
    'isActive': area.isActive,
    'createdAt': Timestamp.fromDate(area.createdAt),
  };
}
