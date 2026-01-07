import 'package:cloud_firestore/cloud_firestore.dart';

import '../entities/access_request.dart';

class AccessRequestDto {
  AccessRequestDto._();

  static AccessRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    AccessRequestType typeFrom(String? s) {
      switch (s) {
        case 'images':
          return AccessRequestType.images;
        case 'location':
          return AccessRequestType.location;
        case 'phone':
        default:
          return AccessRequestType.phone;
      }
    }

    AccessRequestStatus statusFrom(String? s) {
      switch (s) {
        case 'accepted':
          return AccessRequestStatus.accepted;
        case 'rejected':
          return AccessRequestStatus.rejected;
        case 'expired':
          return AccessRequestStatus.expired;
        default:
          return AccessRequestStatus.pending;
      }
    }

    final created =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final expires =
        (data['expiresAt'] as Timestamp?)?.toDate() ??
        created.add(const Duration(hours: 24));

    return AccessRequest(
      id: doc.id,
      propertyId: data['propertyId'] as String? ?? '',
      requesterId: data['requesterId'] as String? ?? '',
      type: typeFrom(data['type'] as String?),
      message: data['message'] as String?,
      status: statusFrom(data['status'] as String?),
      createdAt: created,
      expiresAt: expires,
      decidedAt: (data['decidedAt'] as Timestamp?)?.toDate(),
      decidedBy: data['decidedBy'] as String?,
      ownerId: data['ownerId'] as String?,
    );
  }

  static Map<String, Object?> toMap(AccessRequest r) => {
    'propertyId': r.propertyId,
    'requesterId': r.requesterId,
    'type': r.type.name,
    'message': r.message,
    'status': r.status.name,
    'createdAt': Timestamp.fromDate(r.createdAt),
    'expiresAt': r.expiresAt != null ? Timestamp.fromDate(r.expiresAt!) : null,
    'decidedAt': r.decidedAt != null ? Timestamp.fromDate(r.decidedAt!) : null,
    'decidedBy': r.decidedBy,
    'ownerId': r.ownerId,
  };
}
