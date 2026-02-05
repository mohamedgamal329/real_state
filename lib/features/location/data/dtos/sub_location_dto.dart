import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:real_state/features/models/entities/sub_location.dart';

class SubLocationDto {
  SubLocationDto._();

  static SubLocation fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SubLocation(
      id: doc.id,
      areaId: data['areaId'] as String? ?? '',
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, Object?> toMap(SubLocation subLocation) => {
    'areaId': subLocation.areaId,
    'nameAr': subLocation.nameAr,
    'nameEn': subLocation.nameEn,
    'isActive': subLocation.isActive,
    'createdAt': Timestamp.fromDate(subLocation.createdAt),
  };
}
