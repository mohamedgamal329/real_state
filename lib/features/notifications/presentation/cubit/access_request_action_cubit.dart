import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:real_state/core/errors/localized_exception.dart';
import 'package:real_state/core/constants/user_role.dart';
import 'package:real_state/core/handle_errors/error_mapper.dart';
import 'package:real_state/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:real_state/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:real_state/features/access_requests/domain/usecases/accept_access_request_usecase.dart';
import 'package:real_state/features/access_requests/domain/usecases/reject_access_request_usecase.dart';
import 'package:real_state/features/properties/domain/property_permissions.dart';

import 'access_request_action_state.dart';

class AccessRequestActionCubit extends Cubit<AccessRequestActionState> {
  final AcceptAccessRequestUseCase _acceptAccessRequestUseCase;
  final RejectAccessRequestUseCase _rejectAccessRequestUseCase;
  final NotificationsRepository _notificationsRepository;
  final AuthRepositoryDomain _auth;
  StreamSubscription? _authSub;
  String? _currentUserId;
  UserRole? _currentRole;

  AccessRequestActionCubit(
    this._acceptAccessRequestUseCase,
    this._rejectAccessRequestUseCase,
    this._notificationsRepository,
    this._auth,
  ) : super(const AccessRequestActionInitial()) {
    _authSub = _auth.userChanges.listen((user) {
      _currentUserId = user?.id;
      _currentRole = user?.role;
    });
  }

  Future<String?> accept({
    required String notificationId,
    required String requestId,
    String? targetUserId,
  }) {
    return _process(
      notificationId: notificationId,
      requestId: requestId,
      accepted: true,
      targetUserId: targetUserId,
    );
  }

  Future<String?> reject({
    required String notificationId,
    required String requestId,
    String? targetUserId,
  }) {
    return _process(
      notificationId: notificationId,
      requestId: requestId,
      accepted: false,
      targetUserId: targetUserId,
    );
  }

  Future<String?> _process({
    required String notificationId,
    required String requestId,
    required bool accepted,
    String? targetUserId,
  }) async {
    if (state is AccessRequestActionInProgress) return null;
    emit(const AccessRequestActionInProgress());
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        throw const LocalizedException('error_auth_required');
      }
      if (!canAcceptRejectAccessRequests(_currentRole) ||
          (targetUserId != null &&
              targetUserId.isNotEmpty &&
              targetUserId != userId)) {
        throw const LocalizedException('access_request_action_not_allowed');
      }
      final updated = accepted
          ? await _acceptAccessRequestUseCase(
              requestId: requestId,
              userId: userId,
              role: _currentRole,
            )
          : await _rejectAccessRequestUseCase(
              requestId: requestId,
              userId: userId,
              role: _currentRole,
            );
      await _notificationsRepository.sendAccessRequestDecision(
        request: updated,
        accepted: accepted,
      );
      await _notificationsRepository.markAsRead(notificationId);
      emit(const AccessRequestActionSuccess());
      return null;
    } catch (e, st) {
      final message = mapErrorMessage(e, stackTrace: st);
      emit(AccessRequestActionFailure(message));
      return message;
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
