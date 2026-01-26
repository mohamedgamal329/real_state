import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/access_requests/domain/repositories/access_requests_repository.dart';
import 'package:real_state/features/access_requests/domain/resolve_access_request_target_usecase.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';

class CreateAccessRequestResult {
  final AccessRequest request;
  final bool created;

  const CreateAccessRequestResult({required this.request, required this.created});
}

class CreateAccessRequestUseCase {
  final AccessRequestsRepository _repository;
  final ResolveAccessRequestTargetUseCase _resolveTarget;

  CreateAccessRequestUseCase(this._repository, this._resolveTarget);

  Future<CreateAccessRequestResult> call({
    required Property property,
    required String requesterId,
    required AccessRequestType type,
    String? message,
  }) async {
    final targetUserId = await _resolveTarget.resolveTarget(property);
    if (targetUserId.isEmpty) {
      throw const LocalizedException('access_request_target_missing');
    }
    final latest = await _repository.fetchLatestRequest(
      propertyId: property.id,
      requesterId: requesterId,
      type: type,
    );
    if (latest != null &&
        (latest.status == AccessRequestStatus.pending ||
            latest.status == AccessRequestStatus.accepted)) {
      return CreateAccessRequestResult(request: latest, created: false);
    }
    final created = await _repository.createRequest(
      propertyId: property.id,
      requesterId: requesterId,
      type: type,
      targetUserId: targetUserId,
      message: message?.isEmpty == true ? null : message,
    );
    return CreateAccessRequestResult(request: created, created: true);
  }
}
