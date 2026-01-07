enum AccessRequestType { phone, images, location }

enum AccessRequestStatus { pending, accepted, rejected, expired }

class AccessRequest {
  final String id;
  final String propertyId;
  final String requesterId;
  final AccessRequestType type;
  final AccessRequestStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? message;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? ownerId;

  const AccessRequest({
    required this.id,
    required this.propertyId,
    required this.requesterId,
    required this.type,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.message,
    this.decidedBy,
    this.decidedAt,
    this.ownerId,
  });
}
