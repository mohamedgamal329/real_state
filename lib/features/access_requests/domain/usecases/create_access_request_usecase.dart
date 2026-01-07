import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/access_requests/data/repositories/access_requests_repository.dart';
import 'package:real_state/features/access_requests/domain/resolve_access_request_target_usecase.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/models/entities/property.dart';

class CreateAccessRequestUseCase {
  final AccessRequestsRepository _repository;
  final ResolveAccessRequestTargetUseCase _resolveTarget;

  CreateAccessRequestUseCase(this._repository, this._resolveTarget);

  Future<AccessRequest> call({
    required Property property,
    required String requesterId,
    required AccessRequestType type,
    String? message,
  }) async {
    final targetUserId = await _resolveTarget.resolveTarget(property);
    if (targetUserId.isEmpty) {
      throw const LocalizedException('access_request_target_missing');
    }
    return _repository.createRequest(
      propertyId: property.id,
      requesterId: requesterId,
      type: type,
      targetUserId: targetUserId,
      message: message?.isEmpty == true ? null : message,
    );
  }
}
