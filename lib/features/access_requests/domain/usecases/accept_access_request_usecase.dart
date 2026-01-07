import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/features/access_requests/data/repositories/access_requests_repository.dart';
import 'package:real_state/features/models/entities/access_request.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

class AcceptAccessRequestUseCase {
  final AccessRequestsRepository _repository;

  AcceptAccessRequestUseCase(this._repository);

  Future<AccessRequest> call({
    required String requestId,
    required String userId,
    required UserRole? role,
  }) async {
    final existing = await _repository.fetchById(requestId);
    if (existing == null)
      throw const LocalizedException('access_request_target_missing');
    if (!canDecideAccessRequest(
      request: existing,
      userId: userId,
      role: role,
    )) {
      throw const LocalizedException('access_request_action_not_allowed');
    }
    return _repository.updateStatus(
      requestId: requestId,
      status: AccessRequestStatus.accepted,
      decidedBy: userId,
    );
  }
}
